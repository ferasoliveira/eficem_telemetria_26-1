# Planejamento — Projeto Dashboard (Estação Base)

> **Projeto:** Sistema Integrado de Telemetria — EFICEM / Shell Eco-marathon 2026
> **Subsistema:** Estação Base — Monitoramento em Tempo Real e Análise de Dados
> **Stack:** Vite + React (webapp local em `localhost`) | Backend Node.js para LoRa Serial
> **Gráficos:** Plotly.js (react-plotly.js) | **Mapa:** HTML Canvas 2D
> **Banco de Dados:** SQLite (via `better-sqlite3`)
> **Criado em:** 2026-04-01 | **Atualizado em:** 2026-04-01

---

## 1. Objetivo

Desenvolver o software de dashboard que roda no notebook do box (estação base) para visualização estratégica em tempo real, mapeamento de trajetória do veículo e análise pós-corrida de sessões com sobreposição de dados históricos.

---

## 2. Requisitos Funcionais

### RF-D01 — Recepção de Dados e Redundância

| ID | Requisito | Detalhes |
|----|-----------|----------|
| RF-D01.1 | Recepção via Internet (5G/4G) | **MQTT Subscriber** — tópico `eficem/telemetry` (broker Mosquitto local no notebook) |
| RF-D01.2 | Recepção via LoRa (Receptor USB) | **LILYGO® LoRa32 V2.1** conectado via USB Serial — pacotes de redundância do ESP32-S3 (TX: EBYTE E22-900T) |
| RF-D01.3 | Algoritmo de filtragem por timestamp | Cruzar timestamps dos pacotes 5G e LoRa — usar o que chegar primeiro |
| RF-D01.4 | Fallback automático | Se um canal cai, o outro assume transparentemente sem intervenção |
| RF-D01.5 | Indicador de canal ativo | Mostrar na UI qual canal está sendo usado (5G, LoRa, ou ambos) |

### RF-D02 — Telemetria em Tempo Real

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF-D02.1 | Indicador de **Velocidade Atual** | 🔴 Crítico |
| RF-D02.2 | Indicador de **Consumo de Energia Atual** | 🔴 Crítico |
| RF-D02.3 | Indicador de **Velocidade Média da Sessão** | 🟡 Alto |
| RF-D02.4 | Indicador de **Consumo Médio da Sessão** | 🟡 Alto |
| RF-D02.5 | Gráfico temporal de Velocidade vs. Tempo | 🟡 Alto |
| RF-D02.6 | Gráfico temporal de Consumo vs. Tempo | 🟡 Alto |

### RF-D03 — Mapeamento de Trajetória (Real-Time)

| ID | Requisito | Detalhes |
|----|-----------|----------|
| RF-D03.1 | Desenho do percurso usando coordenadas X, Y | Coordenadas pré-processadas pelo ESP (Sensor Fusion) |
| RF-D03.2 | Atualização do mapa em tempo real | Nova posição desenhada a cada pacote recebido |
| RF-D03.3 | Codificação por cores no mapa | Cor do traço variando com velocidade ou consumo |
| RF-D03.4 | Zoom e pan no mapa | Navegação interativa na visualização do percurso |

### RF-D04 — Histórico e Análise Pós-Corrida

| ID | Requisito | Detalhes |
|----|-----------|----------|
| RF-D04.1 | Visualização de sessões antigas | Dados carregados via LoRa/5G ao vivo OU leitura do pendrive |
| RF-D04.2 | Leitura direta dos CSVs do pendrive | Importar `volta_XX.csv` diretamente do pendrive conectado ao notebook |
| RF-D04.3 | Gráficos sobrepostos: Velocidade vs. Posição | Overlay de múltiplas voltas para comparação |
| RF-D04.4 | Gráficos sobrepostos: Consumo vs. Posição | Overlay de múltiplas voltas para comparação |
| RF-D04.5 | Análise de perfil de condução | Identificar pontos de Burn (aceleração) e Coast (rolagem livre) |
| RF-D04.6 | Recomendações de otimização | Sugerir ajustes de estratégia baseados nos dados históricos |

### RF-D05 — Gerenciamento de Sessões

| ID | Requisito | Detalhes |
|----|-----------|----------|
| RF-D05.1 | Lista de sessões/voltas com metadados | Timestamp, duração, distância, consumo total |
| RF-D05.2 | Seleção de sessões para comparação | Escolher 2+ sessões para overlay |
| RF-D05.3 | Exportação de dados | Exportar relatórios em PDF ou CSV consolidado |

---

## 3. Requisitos Não-Funcionais

| ID | Requisito | Métrica |
|----|-----------|---------|
| RNF-D01 | Latência de exibição (tempo real) | < 500 ms do envio pelo ESP ao render no dashboard |
| RNF-D02 | Capacidade de renderizar 2h+ de dados sem lag | Otimização de gráficos com downsampling se necessário |
| RNF-D03 | Funcionar offline (apenas com LoRa) | Sem dependência de internet para operação local |
| RNF-D04 | Suporte a import de CSV grande (100k+ linhas) | Parsing eficiente com streaming |
| RNF-D05 | UI responsiva e profissional | Design moderno, dark mode, informação densa mas legível |
| RNF-D06 | Rodar em Windows e Linux | Python ou tecnologia web cross-platform |

---

## 4. Arquitetura Proposta

```
┌──────────────────────────────────────────────────────────────────────┐
│                    NOTEBOOK DA BASE (localhost)                       │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              BACKEND (Node.js + Express)                     │    │
│  │                                                              │    │
│  │  ┌───────────────────┐    ┌────────────────────────────┐    │    │
│  │  │ MQTT Subscriber   │    │ LoRa Serial Listener       │    │    │
│  │  │ (Mosquitto local) │    │ (LILYGO LoRa32 V2.1 USB)  │    │    │
│  │  │ Topic:            │    │ SerialPort → JSON Parser   │    │    │
│  │  │ eficem/telemetry  │    │                            │    │    │
│  │  └────────┬──────────┘    └──────────┬─────────────────┘    │    │
│  │           │                          │                      │    │
│  │           └───────────┬──────────────┘                      │    │
│  │                       ▼                                      │    │
│  │           ┌───────────────────────┐                         │    │
│  │           │  Timestamp Merger /   │                         │    │
│  │           │  Dedup & Fallback     │                         │    │
│  │           └───────────┬───────────┘                         │    │
│  │                       ▼                                      │    │
│  │           ┌───────────────────────┐                         │    │
│  │           │  SQLite (Sessions DB) │                         │    │
│  │           └───────────┬───────────┘                         │    │
│  │                       │                                      │    │
│  │              WebSocket Server (:3001)                        │    │
│  │              → Push data to frontend                        │    │
│  └───────────────────────┼──────────────────────────────────────┘    │
│                          ▼                                           │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              FRONTEND (Vite + React — :5173)                 │    │
│  │                                                              │    │
│  │  ┌──────────────┐  ┌────────────────┐  ┌────────────────┐   │    │
│  │  │ Gauges:      │  │ Charts:        │  │ Map:           │   │    │
│  │  │ Velocidade   │  │ V vs T         │  │ Trajetória X,Y │   │    │
│  │  │ Consumo      │  │ C vs T         │  │ (Canvas 2D)    │   │    │
│  │  │ Médias       │  │ (Plotly.js)    │  │ Real-time +    │   │    │
│  │  │              │  │                │  │ Histórico      │   │    │
│  │  └──────────────┘  └────────────────┘  └────────────────┘   │    │
│  │                                                              │    │
│  │  ┌──────────────────────────────────────────────────────┐   │    │
│  │  │  Histórico: Overlay de Voltas + Burn/Coast Map      │   │    │
│  │  └──────────────────────────────────────────────────────┘   │    │
│  │                                                              │    │
│  │  ┌──────────────────────────────────────────────────────┐   │    │
│  │  │  CSV IMPORT: Upload dos arquivos do pendrive          │   │    │
│  │  └──────────────────────────────────────────────────────┘   │    │
│  └──────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 5. Decisões Técnicas (Resolvidas ✅)

| # | Decisão | Escolha | Justificativa |
|---|---------|---------|---------------|
| 1 | Stack tecnológico | **Vite + React** (webapp local) + **Node.js** backend | Moderno, leve, boa performance. Node necessário para serial LoRa. |
| 2 | Protocolo de recepção 5G | **MQTT** (broker **Mosquitto** local no notebook) | O app Flutter publica; o dashboard subscribe. Robusto e padrão IoT. |
| 3 | Biblioteca de gráficos | **Plotly.js** (`react-plotly.js`) | Interativo por padrão (zoom/pan nativo), ótimo para séries temporais. |
| 4 | Módulo LoRa receptor | **LILYGO® LoRa32 V2.1** via USB Serial | Conectado ao notebook. TX no ESP = EBYTE E22-900T. Comunicação serial. |
| 5 | Banco de dados de sessões | **SQLite** (`better-sqlite3`) | Arquivo único, zero config, queries SQL. Suporta milhões de linhas. |
| 6 | Mapa de trajetória | **HTML Canvas 2D** | Leve e nativo no browser. Até ~50k pontos sem problema. Zoom/pan custom. |

---

## 6. Fases de Execução

### Fase 1 — Scaffolding e Recepção de Dados

- [ ] Criar projeto Vite + React com TypeScript (`npx create-vite`)
- [ ] Criar backend Node.js + Express para serial e WebSocket
- [ ] Instalar e configurar **Mosquitto** como MQTT broker local
- [ ] Implementar MQTT subscriber no backend (tópico `eficem/telemetry`)
- [ ] Implementar listener serial para **LILYGO LoRa32 V2.1** (USB → JSON parser)
- [ ] Implementar Timestamp Merger (dedup + fallback automático)
- [ ] Configurar **SQLite** (`better-sqlite3`) para persistência de sessões
- [ ] WebSocket server (:3001) para push de dados ao frontend React
- [ ] Testes de recepção com dados simulados em ambos os canais

### Fase 2 — Telemetria em Tempo Real

- [ ] Criar layout principal do dashboard em React (dark mode, design profissional)
- [ ] Implementar gauges de Velocidade e Consumo atuais (componentes React)
- [ ] Implementar cálculo de médias da sessão
- [ ] Implementar gráficos temporais com **Plotly.js** (`react-plotly.js`): V vs T, C vs T
- [ ] Indicador visual de canal ativo (MQTT / LoRa / ambos)
- [ ] Testes de atualização em tempo real (< 500ms)

### Fase 3 — Mapeamento de Trajetória

- [ ] Implementar componente React com **HTML Canvas 2D** para trajetória X, Y
- [ ] Atualização em tempo real a cada novo ponto recebido via WebSocket
- [ ] Codificação por cores (velocidade ou consumo) com gradiente no traço
- [ ] Controles de zoom e pan (wheel + drag)
- [ ] Testes de performance com 10k+ pontos

### Fase 4 — Histórico e Análise Pós-Corrida

- [ ] Implementar importação de CSVs do pendrive
- [ ] Implementar lista de sessões com metadados
- [ ] Implementar overlay de múltiplas voltas no mapa
- [ ] Gráficos sobrepostos: Velocidade vs. Posição na Pista
- [ ] Gráficos sobrepostos: Consumo vs. Posição na Pista
- [ ] Implementar análise de perfil Burn/Coast
- [ ] Exportação de relatórios (PDF/CSV)

### Fase 5 — Integração e Testes de Sistema

- [ ] Teste ponta-a-ponta: ESP → BLE → App → 5G → Dashboard (canal 1)
- [ ] Teste ponta-a-ponta: ESP → LoRa → Dashboard (canal 2)
- [ ] Teste de failover: desligar um canal e verificar continuidade
- [ ] Teste de longa duração (2h+ de dados contínuos)
- [ ] Teste de importação de CSV grande pós-corrida
- [ ] Teste de campo no dia da competição (ambiente real)

---

## 7. Riscos e Mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Perda de ambos os canais (5G + LoRa) | Crítico | Dados salvos no pendrive — análise pós-corrida sempre possível |
| Lag nos gráficos com muitos pontos | Alto | Downsampling dinâmico + renderização em canvas otimizado |
| Incompatibilidade do LILYGO LoRa32 V2.1 | Médio | Testar módulo USB e firmware antecipadamente; bridge serial validada |
| Notebook lento / tela pequena | Médio | Otimizar bundle; UI responsiva; testar no hardware real |
| Dados de timestamp dessincronizados | Médio | NTP sync no ESP + tolerância de merge de ±50ms |

---

## 8. Critérios de Aceitação

- [ ] Dashboard recebe dados via 5G com latência < 500ms
- [ ] Dashboard recebe dados via LoRa como fallback funcional
- [ ] Gauges de velocidade e consumo atualizados em tempo real
- [ ] Trajetória X, Y desenhada corretamente no mapa
- [ ] Overlay de voltas funciona com dados de múltiplas sessões
- [ ] Importação de CSV do pendrive funciona sem erros
- [ ] Dashboard estável por 2h+ de uso contínuo
- [ ] Perfil Burn/Coast identificado corretamente nos dados históricos

---

> **Referências:**
> - [escopo.md](../docs/escopo.md) — Seção 4 (Estação Base e Análise de Dados)
> - [requisitos_competicao.md](../docs/requisitos_competicao.md) — Software desenvolvido para a SEM
