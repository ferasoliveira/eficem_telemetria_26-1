# Escopo do Projeto: Sistema Integrado de Telemetria e Monitoramento

## 1. Visão Geral
Desenvolvimento de um sistema de telemetria multicamadas para o veículo elétrico da equipe na Shell Eco-marathon. O sistema é composto por um nó sensor embarcado (ESP32-S3 com suporte nativo a USB Host), um aplicativo móvel (interface do piloto e gateway 5G) e uma aplicação de dashboard na base (monitoramento, trajetória em tempo real e análise de histórico).

---

## 2. Hardware Embarcado (ESP32-S3)
O microcontrolador ESP32-S3 atuará como a central de aquisição, processamento inicial (Edge Computing) e distribuição de dados, aproveitando sua interface USB OTG nativa.

### 2.1. Sensores e Entradas
* **Sensor de Efeito Hall (Encoder):** Leitura de rotação da roda para cálculo de velocidade linear e distância.
* **Célula de Carga/Potenciômetro:** Leitura da posição/força do pedal de aceleração.
* **Sensores de Tensão e Corrente:** Monitoramento do consumo da bateria de propulsão.
* **IMU (Acelerômetro + Giroscópio):** Leitura de taxas de rotação (Yaw) e forças inerciais.
* **Armazenamento USB (Pendrive):** Pendrive conectado diretamente aos pinos D- (GPIO 19) e D+ (GPIO 20) do ESP32-S3 para registro de logs locais.
* **Botão Físico de Controle de Sessão:** Botão externo no painel conectado a um pino de interrupção (Interrupt) do ESP para controle de medições/voltas.

### 2.2. Processamento Interno e Lógica (Edge Computing)
O firmware do ESP32-S3 processará os dados brutos antes do envio, aliviando o processamento do dashboard:
* **Odometria Integrada (Sensor Fusion):** Eliminação do *drift* clássico de IMUs substituindo a dupla integração do acelerômetro pelo dado real do encoder.
  * O Giroscópio (Eixo Z / Yaw) fornece a orientação angular ($\theta$).
  * O Encoder fornece a velocidade linear exata ($v$).
  * O ESP32-S3 calcula as coordenadas locais ($X$ e $Y$) iterativamente usando trigonometria: $X_k=X_{k-1}+v_k\cdot\cos(\theta_k)\cdot\Delta t$ e $Y_k=Y_{k-1}+v_k\cdot\sin(\theta_k)\cdot\Delta t$.
  * O Acelerômetro é utilizado apenas via filtro (ex: Filtro Complementar) para calcular a inclinação (Pitch/Roll) e compensar os erros do giroscópio em rampas.
* **Consumo Energético:** Cálculo da média de consumo de energia do último 1 segundo (janela deslizante).
* **Controle de Sessão (Rotina do Botão):** * Ao ser pressionado, o ESP fecha com segurança o arquivo `.csv` atual aberto em escrita no pendrive.
  * O arquivo é salvo com um identificador de histórico (ex: `circuito_01.csv`).
  * As variáveis integrativas de cálculo (distância, consumo acumulado, posição X e Y) são zeradas.
  * Um novo arquivo (ex: `circuito_02.csv`) é criado no pendrive e a nova medição começa limpa.

### 2.3. Taxas de Amostragem (Tarefas)
* **20 ms (50 Hz):** Leitura do encoder e cálculo de velocidade linear.
* **50 ms (20 Hz):** Leitura da IMU, processamento do Filtro Complementar e atualização das coordenadas X e Y (Sensor Fusion).
* **100 ms (10 Hz):** Leitura de corrente/tensão e cálculo de consumo médio.

### 2.4. Prioridades de Saída de Dados
1. **Prioridade Máxima (Interrupção de Hardware):** Leitura do botão de reset de sessão e encerramento/salvamento seguro do arquivo no pendrive.
2. **Prioridade Alta (Bluetooth/BLE):** Envio dos pacotes de dados processados (Velocidade, Consumo e Coordenadas X, Y) para o celular do piloto.
3. **Prioridade Média (Datalogger USB):** Escrita contínua da linha de dados atual no arquivo `.csv` ativo diretamente no pendrive via interface USB MSC.
4. **Prioridade Baixa (LoRa):** Transmissão do pacote de redundância (Velocidade, Consumo, Coordenadas X e Y) via rádio frequência para a base.

---

## 3. Interface do Piloto e Gateway (App Flutter)
Aplicativo mobile rodando em um smartphone no painel do veículo.

### 3.1. Frontend (UI do Piloto)
* Conexão via Bluetooth (BLE) ou Wi-Fi local com o ESP32-S3.
* Exibição em tempo real de **Velocidade** e **Consumo Atual**.
* Alerta visual de início/fim de sessão de medição (acionado pelo botão do ESP32-S3).

### 3.2. Backend (Background Task)
* Coleta e empacotamento dos dados processados vindos do ESP.
* Transmissão assíncrona contínua via rede 5G/4G para o servidor da base (Websockets, MQTT ou HTTP POST).

---

## 4. Estação Base e Análise de Dados (Dashboard)
Software no notebook do box (Python/Dash, Node, etc.) para visualização estratégica e análise pós-corrida.

### 4.1. Recepção de Dados e Tratamento de Redundância
* O sistema escuta simultaneamente os pacotes via internet (5G) e rádio (receptor LoRa USB).
* Algoritmo de filtragem cruza o `timestamp` para desenhar os gráficos usando o pacote que chegar primeiro, utilizando a outra rede como *fallback* automático em caso de perda de sinal ou interferência.

### 4.2. Interface Principal (Real-Time)
* **Telemetria:** Indicadores de velocidade e consumo atuais e médios da sessão.
* **Mapeamento de Trajetória:** Desenho do percurso do veículo desenhando as coordenadas locais (X e Y) já calculadas e pré-processadas pelo ESP32-S3.

### 4.3. Histórico e Otimização
* Visualização das sessões antigas (carregadas via LoRa/5G ao vivo ou pela leitura direta do pendrive no notebook após a corrida).
* Gráficos sobrepostos de **Velocidade e Consumo vs. Posição na Pista**.
* Análise do perfil de condução para ajustar pontos ideais de aceleração (Burn) e rolagem livre (Coast) para as próximas voltas.