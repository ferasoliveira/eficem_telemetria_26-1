# Requisitos Obrigatórios: Categoria Battery Electric (SEM 2026)

Este guia consolida as normas técnicas e de segurança para o setor de elétrica, conforme o Capítulo I das regras oficiais.

## 1. Sistema de Propulsão e Controle
* **Configuração do Drive Train**: Restrito a no máximo um dispositivo de armazenamento de energia e até dois motores elétricos.
* **Controlador do Motor**: Deve ser construído especificamente para a Shell Eco-marathon; o uso de controladores comerciais ou kits de avaliação é proibido.
* **Marcação SEM**: Controladores que utilizam placas de circuito impresso (PCBs) devem incluir o texto **"SEM"** gravado na máscara de corrosão da placa.
* **Software**: Deve ser desenvolvido ou integrado especificamente para a competição.

## 2. Sistema de Baterias e BMS
* **Tipo de Bateria**: Apenas baterias baseadas em **Lítio** são permitidas para propulsão.
* **Capacidade Máxima**: O limite para qualquer bateria de lítio é de **1.000 Wh**.
* **BMS (Battery Management System)**:
    * Deve fornecer proteção de nível de célula contra sobretensão, descarga excessiva e sobrecorrente.
    * **Isolamento Automático**: O BMS deve isolar a bateria automaticamente, sem intervenção do operador, caso qualquer parâmetro saia da faixa.
    * O BMS deve estar localizado no pacote físico da bateria e ser alimentado diretamente por ela.
* **Montagem e Segurança**:
    * A bateria deve estar atrás da antepara (bulkhead), isolada do motorista.
    * É obrigatório o uso de uma bandeja de contenção metálica sólida ou bolsa de carregamento de bateria.
    * Proibido o uso de Velcro ou materiais elásticos para montagem.

## 3. Segurança Elétrica e Tensões
* **Tensão Máxima**: A voltagem em qualquer ponto do veículo não deve exceder **60V** por projeto.
* **Isolamento de Chassi**: Ambos os circuitos (positivo e negativo) da bateria de propulsão devem estar eletricamente isolados do corpo do veículo e componentes metálicos.
* **Proteção de Curto-Circuito**: Fusíveis ou disjuntores devem ser instalados no condutor positivo a no máximo **300 mm** do terminal da bateria.
* **Fiação e Conexões**:
    * Cabos devem estar em boas condições e protegidos contra sobrecarga elétrica.
    * **Emendas (splices) não são permitidas**.
    * Terminais de alta tensão expostos devem ser protegidos contra curto-circuito acidental.
* **Gabinete Transparente**: Enclosures elétricos devem ser de material transparente ou ter tampa transparente para permitir a visualização do conteúdo pelos inspetores.

## 4. Joulemetro (Medição de Energia)
* **Posicionamento**: Deve ser instalado entre a bateria e o sistema elétrico do veículo.
* **Acessibilidade**: Deve estar no compartimento do motor, com visor legível por fora e botões acessíveis.
* **Medição Total**: Toda a energia (propulsão e acessórios) deve ser medida, exceto o circuito da buzina e sistemas de ventilação/comunicação autônomos.

## 5. Parada de Emergência e Segurança
* **Isolamento Físico**: O sistema deve fornecer isolamento elétrico físico (air gap) da bateria de propulsão via relé normalmente aberto ou interruptor físico.
* **Botão Externo**: Deve ser um botão tipo "cogumelo" vermelho de trava, que se sobressai da carroceria e é reativado apenas por rotação.
* **Dead Man's Switch**: Interruptor de presença do motorista (no volante) que interrompe a propulsão se solto.
* **Buzina**: Elétrica, tom único contínuo, emitindo mais de **85 dBA** a 4 metros.

## 6. Documentação para Inspeção Técnica
A equipe deve apresentar uma pasta impressa contendo:
* Esquema elétrico detalhado com níveis de tensão e valores de fusíveis.
* Documentação do fabricante da bateria e BMS (limites de proteção e química).
* Documentação de design do controlador de motor construído pela equipe (layouts de PCB e diagramas de controle).