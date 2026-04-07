# Planejamento — Projeto Celular (App Flutter)

> **Projeto:** Sistema Integrado de Telemetria — EFICEM / Shell Eco-marathon 2026
> **Subsistema:** Interface do Piloto e Gateway de Dados
> **Framework:** Flutter (Dart) — Android Only
> **Orientação:** Landscape (fixa)
> **Criado em:** 2026-04-01 | **Atualizado em:** 2026-04-01

---

## 1. Objetivo

Desenvolver o aplicativo mobile que roda no smartphone do piloto, fixado no painel do veículo. O app tem **dois papéis simultâneos**:

1. **Frontend** — Interface visual do piloto com dados em tempo real.
2. **Backend (Gateway 5G)** — Retransmissão dos dados do ESP32-S3 para a estação base via rede celular.

---

## 2. Requisitos Funcionais

### RF-C01 — Conexão com o ESP32-S3

| ID | Requisito | Detalhes |
|----|-----------|----------|
| RF-C01.1 | Conexão via Bluetooth BLE | Pareamento e recepção dos pacotes de telemetria do ESP |
| RF-C01.2 | Fallback via Wi-Fi local | Caso BLE não esteja disponível, conectar via Wi-Fi direto do ESP |
| RF-C01.3 | Reconexão automática | Caso a conexão caia, reconectar sem intervenção do piloto |
| RF-C01.4 | Indicador de status de conexão | Ícone visual mostrando se está conectado ou desconectado do ESP |

### RF-C02 — Interface do Piloto (Frontend)

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF-C02.1 | Exibição em tempo real de **Velocidade** | 🔴 Crítico |
| RF-C02.2 | Exibição em tempo real de **Consumo Atual** | 🔴 Crítico |
| RF-C02.3 | Alerta visual de início/fim de sessão de medição | 🟡 Alto |
| RF-C02.4 | UI otimizada para leitura em movimento (alto contraste, fontes grandes) | 🟡 Alto |
| RF-C02.5 | Orientação fixa em **Landscape** | ✅ Definido |
| RF-C02.6 | Modo tela cheia (sem barra de status do sistema) | 🟢 Médio |

### RF-C03 — Gateway de Dados (Backend / Background Task)

| ID | Requisito | Detalhes |
|----|-----------|----------|
| RF-C03.1 | Coleta dos dados processados vindos do ESP | Parsing do pacote BLE → struct interna |
| RF-C03.2 | Empacotamento dos dados para transmissão | Serialização em **JSON compacto** |
| RF-C03.3 | Transmissão assíncrona via rede 5G/4G | Canal permanente para o notebook da base |
| RF-C03.4 | Protocolo de comunicação com a base | **MQTT** (publish no tópico `eficem/telemetry`) |
| RF-C03.5 | Destino da transmissão | **Direto para o notebook via IP** (sem servidor intermediário) |
| RF-C03.6 | Buffer local em caso de perda de rede | Armazenar dados enquanto sem internet e enviar ao reconectar |
| RF-C03.7 | Background task que não morre com tela bloqueada | Serviço foreground Android com notificação permanente |

### RF-C04 — Notificações de Sessão

| ID | Requisito | Detalhes |
|----|-----------|----------|
| RF-C04.1 | Receber evento de troca de sessão do ESP | O ESP envia flag quando o botão é pressionado |
| RF-C04.2 | Alerta visual/sonoro ao piloto | Feedback claro de que a volta mudou |
| RF-C04.3 | Contador de sessão/volta visível na UI | Exibir "Volta 1", "Volta 2", etc. |

---

## 3. Requisitos Não-Funcionais

| ID | Requisito | Métrica |
|----|-----------|---------|
| RNF-C01 | Latência de exibição de dados | < 200 ms do recebimento BLE ao render na tela |
| RNF-C02 | Consumo de bateria do celular | Mínimo — app otimizado para horas de operação |
| RNF-C03 | Estabilidade do background task | 0 crashes durante corrida (mínimo 2h contínuas) |
| RNF-C04 | UI legível sob luz solar | Alto contraste, cores vibrantes, fontes ≥ 24sp |
| RNF-C05 | Compatibilidade | **Android 10+** (build APK direto) |
| RNF-C06 | Tempo de startup | < 3 segundos até a UI estar pronta |
| RNF-C07 | Dados nunca perdidos | Buffer local garante 100% de entrega eventual à base |

---

## 4. Arquitetura Proposta

```
┌────────────────────────────────────────────────────────────┐
│                    App Flutter (Celular)                    │
│                                                            │
│  ┌────────────────────────────────────────────────────┐    │
│  │                   FRONTEND (UI)                     │    │
│  │                                                     │    │
│  │   ┌──────────────┐    ┌──────────────────────┐     │    │
│  │   │  Velocímetro  │    │  Consumo Instantâneo │     │    │
│  │   │  (Widget)     │    │  (Widget)            │     │    │
│  │   └──────────────┘    └──────────────────────┘     │    │
│  │                                                     │    │
│  │   ┌──────────────────────────────────────────┐     │    │
│  │   │  Alerta de Sessão + Contador de Volta    │     │    │
│  │   └──────────────────────────────────────────┘     │    │
│  │                                                     │    │
│  │   ┌──────────────┐                                 │    │
│  │   │ Status Conn. │  🟢 BLE  🔴 Offline            │    │
│  │   └──────────────┘                                 │    │
│  └────────────────────────────────────────────────────┘    │
│                                                            │
│  ┌────────────────────────────────────────────────────┐    │
│  │            BACKEND (Background Service)              │    │
│  │                                                     │    │
│  │   ┌────────┐    ┌──────────┐    ┌──────────────┐   │    │
│  │   │ BLE RX │───▶│  Buffer  │───▶│ MQTT Publish │   │    │
│  │   │        │    │  Local   │    │ → JSON → IP  │   │    │
│  │   └────────┘    └──────────┘    └──────────────┘   │    │
│  │                                                     │    │
│  └────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────┘
         │ BLE                              │ MQTT (5G/4G)
         ▼                                  ▼
   ┌───────────┐                   ┌─────────────────────┐
   │  ESP32-S3 │                   │  Notebook da Base   │
   │ (Veículo) │                   │  (Mosquitto + Vite) │
   └───────────┘                   └─────────────────────┘
```

---

## 5. Decisões Técnicas (Resolvidas ✅)

| # | Decisão | Escolha | Justificativa |
|---|---------|---------|---------------|
| 1 | Protocolo de comunicação | **MQTT** | Pub/sub leve, ideal para IoT, QoS configurável, resiliente a conexões instáveis |
| 2 | Formato de serialização | **JSON compacto** | Legível, fácil de debugar, compatível com todo o stack |
| 3 | Orientação da tela | **Landscape** | Celular montado horizontalmente no painel; mais espaço para gauges lado a lado |
| 4 | Plataforma do piloto | **Android** | Build APK direto, sem necessidade de Mac/Apple Developer. Foreground service nativo |
| 5 | Destino do gateway | **Direto para o notebook (IP)** | Sem intermediário cloud; app se conecta via IP do notebook na rede 4G/5G |

---

## 6. Fases de Execução

### Fase 1 — Scaffolding e Conexão BLE

- [ ] Criar projeto Flutter com estrutura limpa (Clean Architecture ou similar)
- [ ] Configurar dependências: `flutter_blue_plus`, `provider`/`riverpod`
- [ ] Implementar service de conexão BLE
- [ ] Scan, pareamento e leitura de characteristic do ESP32-S3
- [ ] Reconexão automática com retry exponencial
- [ ] Testes com dados simulados (mock BLE)

### Fase 2 — Interface do Piloto

- [ ] Criar tela principal com velocímetro e consumo
- [ ] Widgets de alto contraste otimizados para leitura em movimento
- [ ] Indicador de status de conexão (BLE conectado/desconectado)
- [ ] Alerta visual/sonoro de troca de sessão
- [ ] Contador de volta visível
- [ ] Modo tela cheia (imersivo)
- [ ] Testes de legibilidade sob diferentes condições de luz

### Fase 3 — Gateway MQTT (Background Service)

- [ ] Implementar parsing do pacote BLE → modelo Dart interno
- [ ] Implementar buffer local (SQLite) para resiliência
- [ ] Implementar cliente MQTT (`mqtt_client`) publicando no tópico `eficem/telemetry`
- [ ] Serialização dos dados em JSON compacto antes do publish
- [ ] Configurar foreground service Android com notificação permanente
- [ ] Implementar lógica de reconexão MQTT e reenvio de dados bufferizados
- [ ] Configurar endereço IP do notebook como variável (Settings do app)
- [ ] Testes de perda/retomada de rede (buffer → flush)

### Fase 4 — Integração e Testes

- [ ] Teste ponta-a-ponta: ESP → BLE → App → 5G → Dashboard
- [ ] Teste de estabilidade (2h+ contínuas sem crash)
- [ ] Teste de consumo de bateria do celular
- [ ] Teste de campo no veículo com vibração e movimento
- [ ] Ajustes de UI baseados em feedback do piloto real

---

## 7. Riscos e Mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Perda de conexão BLE por vibração | Alto | Reconexão automática < 2s + buffer local |
| App morto pelo OS em background | Alto | Foreground service + notification permanente |
| Latência alta na rede 5G durante evento | Médio | Buffer local + envio batch; dados são exibidos localmente sem depender da rede |
| Celular do piloto com tela pequena | Médio | UI adaptativa com breakpoints; testar no dispositivo real |
| Reflexo solar na tela | Médio | Alto contraste + possibilidade de tema escuro com cores neon |

---

## 8. Critérios de Aceitação

- [ ] App conecta ao ESP via BLE em < 5 segundos
- [ ] Velocidade e consumo atualizados em tempo real (latência < 200ms)
- [ ] Alerta de sessão visível e audível ao piloto
- [ ] Dados retransmitidos para a base sem perda (eventual delivery garantido)
- [ ] App funciona por 2h+ contínuas sem crash nem freeze
- [ ] UI legível sob condições reais de pilotagem (vibração, sol)

---

> **Referências:**
> - [escopo.md](../docs/escopo.md) — Seção 3 (Interface do Piloto e Gateway)
> - [requisitos_competicao.md](../docs/requisitos_competicao.md) — Software desenvolvido para a SEM
