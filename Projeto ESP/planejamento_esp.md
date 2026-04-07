# Planejamento — Projeto ESP32-S3 (Nó Embarcado)

> **Projeto:** Sistema Integrado de Telemetria — EFICEM / Shell Eco-marathon 2026
> **Subsistema:** Hardware Embarcado — Central de Aquisição e Edge Computing
> **MCU:** ESP32-S3 (USB OTG nativo)
> **LoRa TX:** EBYTE E22-900T | **LoRa RX (Base):** LILYGO® LoRa32 V2.1
> **Protocolo com App:** BLE → JSON compacto | **Protocolo App→Base:** MQTT
> **Criado em:** 2026-04-01 | **Atualizado em:** 2026-04-01

---

## 1. Objetivo

Desenvolver o firmware do ESP32-S3 que atua como central de aquisição, processamento de borda (Edge Computing) e distribuição de dados do veículo elétrico para o app do piloto (BLE) e a estação base (LoRa).

---

## 2. Requisitos Funcionais

### RF-E01 — Leitura de Sensores

| ID | Sensor | Grandeza | Pino / Interface |
|----|--------|----------|------------------|
| RF-E01.1 | Sensor de Efeito Hall (Encoder) | Rotação da roda → Velocidade linear e Distância | GPIO (Interrupt) |
| RF-E01.2 | Célula de Carga / Potenciômetro | Posição/força do pedal de aceleração | ADC |
| RF-E01.3 | Sensores de Tensão e Corrente | Consumo da bateria de propulsão (V e I) | ADC |
| RF-E01.4 | IMU (Acelerômetro + Giroscópio) | Taxas de rotação (Yaw) e forças inerciais | I2C / SPI |
| RF-E01.5 | Botão Físico de Sessão | Controle de medições/voltas | GPIO (Interrupt) |

### RF-E02 — Processamento de Borda (Edge Computing)

| ID | Funcionalidade | Descrição |
|----|----------------|-----------|
| RF-E02.1 | Odometria Integrada (Sensor Fusion) | Fusão Encoder + Giroscópio (Yaw) para posição X,Y sem drift. Acelerômetro apenas via Filtro Complementar para Pitch/Roll. |
| RF-E02.2 | Cálculo de Posição Iterativo | $X_k = X_{k-1} + v_k \cdot \cos(\theta_k) \cdot \Delta t$ e $Y_k = Y_{k-1} + v_k \cdot \sin(\theta_k) \cdot \Delta t$ |
| RF-E02.3 | Consumo Energético Médio | Janela deslizante de 1 segundo sobre leituras de V × I |
| RF-E02.4 | Controle de Sessão (Botão) | Ao pressionar: fechar CSV atual → salvar (`volta_XX.csv`) → zerar variáveis integrativas → criar novo CSV |

### RF-E03 — Saída de Dados (por prioridade)

| Prioridade | Canal | Dados | Obs |
|------------|-------|-------|-----|
| **Máxima** (ISR) | Botão de Reset | Encerramento/salvamento seguro do CSV no pendrive | Interrupção de hardware |
| **Alta** | Bluetooth BLE | Velocidade, Consumo, Coordenadas X, Y | Pacotes otimizados para o app do piloto |
| **Média** | USB MSC (Pendrive) | Linha completa de dados em `.csv` | Escrita contínua via USB Host (D- GPIO19, D+ GPIO20) |
| **Baixa** | LoRa (RF) — **EBYTE E22-900T** | Velocidade, Consumo, Coordenadas X, Y | Pacote de redundância para a base (RX: LILYGO LoRa32 V2.1) |

### RF-E04 — Datalogger USB

| ID | Requisito |
|----|-----------|
| RF-E04.1 | Pendrive conectado via pinos D- (GPIO 19) e D+ (GPIO 20) usando USB Host nativo |
| RF-E04.2 | Formato de arquivo: `.csv` com identificador de sessão (`volta_01.csv`, `volta_02.csv`, ...) |
| RF-E04.3 | Escrita contínua com flush periódico para evitar perda de dados |
| RF-E04.4 | Fechamento seguro do arquivo na interrupção do botão (antes de zerar variáveis) |

---

## 3. Requisitos Não-Funcionais

| ID | Requisito | Métrica |
|----|-----------|---------|
| RNF-E01 | Taxa de amostragem do Encoder | 50 Hz (20 ms) |
| RNF-E02 | Taxa de amostragem da IMU + Sensor Fusion | 20 Hz (50 ms) |
| RNF-E03 | Taxa de amostragem de Tensão/Corrente | 10 Hz (100 ms) |
| RNF-E04 | Latência máxima do botão de sessão | < 10 ms (ISR) |
| RNF-E05 | Uso de FreeRTOS para gerenciamento de tarefas | Obrigatório |
| RNF-E06 | Software desenvolvido especificamente para a SEM | Regra oficial (Art. 1) |
| RNF-E07 | Confiabilidade do datalogger | Sem perda de dados em shutdown inesperado |

---

## 4. Arquitetura Proposta

```
┌──────────────────────────────────────────────────────┐
│                   ESP32-S3 (FreeRTOS)                │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │ Task 50Hz│  │ Task 20Hz│  │   Task 10Hz       │  │
│  │ Encoder  │  │ IMU +    │  │   V/I + Consumo   │  │
│  │ → v, d   │  │ Fusion   │  │   médio (1s)      │  │
│  │          │  │ → X, Y   │  │                   │  │
│  └────┬─────┘  └────┬─────┘  └────────┬──────────┘  │
│       │              │                 │             │
│       └──────────────┼─────────────────┘             │
│                      ▼                               │
│              ┌───────────────┐                       │
│              │  Packet Forge │ (struct com timestamp)│
│              └──┬────┬────┬─┘                       │
│                 │    │    │                           │
│    ┌────────────┘    │    └──────────────┐           │
│    ▼                 ▼                   ▼           │
│ ┌──────┐      ┌──────────┐        ┌──────────┐     │
│ │ BLE  │      │ USB MSC  │        │  LoRa TX │     │
│ │(Alta)│      │ Pendrive │        │  (Baixa) │     │
│ │      │      │ (Média)  │        │          │     │
│ └──────┘      └──────────┘        └──────────┘     │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │ ISR: Botão Físico → Fecha CSV → Zera → Novo │   │
│  │ (Prioridade MÁXIMA — Interrupção de HW)      │   │
│  └──────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

---

## 5. Fases de Execução

### Fase 1 — Scaffolding e Infraestrutura

- [ ] Criar projeto PlatformIO para ESP32-S3
- [ ] Configurar FreeRTOS com tarefas base (50Hz, 20Hz, 10Hz)
- [ ] Definir estrutura de dados do pacote de telemetria (struct com timestamp)
- [ ] Configurar pinos de acordo com o hardware real

### Fase 2 — Aquisição de Sensores

- [ ] Implementar driver do Encoder (Hall) com interrupção para contagem de pulsos
- [ ] Implementar leitura ADC do pedal (Célula de Carga / Potenciômetro)
- [ ] Implementar leitura ADC dos sensores de Tensão e Corrente
- [ ] Implementar driver da IMU via I2C/SPI (acelerômetro + giroscópio)
- [ ] Testes unitários de cada sensor isoladamente

### Fase 3 — Edge Computing

- [ ] Implementar cálculo de velocidade linear a partir do encoder
- [ ] Implementar Filtro Complementar para Pitch/Roll (acelerômetro)
- [ ] Implementar Sensor Fusion: Encoder (v) + Giroscópio (θ) → posição X, Y
- [ ] Implementar cálculo de consumo médio (janela deslizante 1s)
- [ ] Validar precisão da odometria com dados simulados

### Fase 4 — Comunicação

- [ ] Implementar servidor BLE com characteristic para pacote de telemetria
- [ ] Implementar USB Host MSC para leitura/escrita no pendrive
- [ ] Implementar driver LoRa TX (**EBYTE E22-900T**) para envio de pacotes de redundância
- [ ] Testes de comunicação em cada canal separadamente

### Fase 5 — Datalogger e Controle de Sessão

- [ ] Implementar rotina de escrita contínua no CSV (pendrive)
- [ ] Implementar ISR do botão com debounce
- [ ] Implementar rotina de sessão: fechar CSV → salvar → zerar → novo CSV
- [ ] Testar cenários de falha (desconexão do pendrive, power loss)

### Fase 6 — Integração e Testes de Sistema

- [ ] Integrar todas as tasks FreeRTOS com prioridades definidas
- [ ] Teste de estresse: todas as tarefas rodando simultaneamente
- [ ] Validar que as taxas de amostragem são respeitadas sob carga
- [ ] Teste de comunicação ponta-a-ponta (ESP → BLE → App e ESP → LoRa → Base)
- [ ] Teste de campo no veículo real

---

## 6. Riscos e Mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Conflito USB Host + Wi-Fi (ambos usam muito DMA) | Alto | Priorizar BLE sobre Wi-Fi; USB Host em core dedicado |
| Perda de dados no pendrive por desconexão | Alto | Flush periódico + fechamento seguro na ISR do botão |
| Drift na odometria por erro acumulado do giroscópio | Médio | Filtro Complementar + recalibração por sessão |
| Saturação de banda BLE com muitos dados | Médio | Pacotes compactos (struct binário, não JSON) |
| Interferência LoRa no ambiente da pista | Médio | LoRa como redundância, não como canal primário |

---

## 7. Critérios de Aceitação

- [ ] Todos os sensores lidos nas taxas especificadas (50Hz, 20Hz, 10Hz)
- [ ] Posição X, Y calculada com erro < 5% em trajetória circular de teste
- [ ] Dados chegando no app via BLE com latência < 200ms
- [ ] CSV salvo corretamente no pendrive com todas as colunas
- [ ] Troca de sessão (botão) funciona sem perda de dados
- [ ] Pacote LoRa recebido na base com taxa de sucesso > 90%

---

> **Referências:**
> - [escopo.md](../docs/escopo.md) — Seção 2 (Hardware Embarcado)
> - [requisitos_competicao.md](../docs/requisitos_competicao.md) — Software deve ser desenvolvido especificamente para a SEM
