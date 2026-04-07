# 📱 Guia de Setup — Projeto Celular (EFICEM Pilot)

> **Plataforma:** Android only | **Framework:** Flutter (Dart)
> **Tempo estimado de setup:** ~45–60 minutos (com downloads)

Este guia cobre **tudo** que você precisa para preparar o ambiente de desenvolvimento do zero no Windows.

---

## Índice

1. [Pré-requisitos do Sistema](#1-pré-requisitos-do-sistema)
2. [Instalar o Flutter SDK](#2-instalar-o-flutter-sdk)
3. [Instalar o Android Studio](#3-instalar-o-android-studio)
4. [Configurar o Android SDK](#4-configurar-o-android-sdk)
5. [Aceitar as Licenças do Android](#5-aceitar-as-licenças-do-android)
6. [Verificar a Instalação (flutter doctor)](#6-verificar-a-instalação-flutter-doctor)
7. [Inicializar o Projeto Flutter](#7-inicializar-o-projeto-flutter)
8. [Baixar as Fontes](#8-baixar-as-fontes)
9. [Instalar as Dependências](#9-instalar-as-dependências)
10. [Executar o App](#10-executar-o-app)
11. [Estrutura do Projeto](#11-estrutura-do-projeto)
12. [Solução de Problemas](#12-solução-de-problemas)

---

## 1. Pré-requisitos do Sistema

Antes de começar, verifique que você tem:

| Requisito | Status | Como verificar |
|-----------|--------|----------------|
| **Windows 10/11** (64-bit) | ✅ | — |
| **Git** | ✅ Instalado (v2.49.0) | `git --version` |
| **Espaço em disco** | Mínimo **10 GB** livres | Para Flutter SDK + Android SDK |
| **Conexão com internet** | Necessária | Para downloads do SDK |

> ⚠️ O **Java 8** foi detectado na máquina. O Android SDK atual exige **Java 17**. O Android Studio já vem com o JDK embutido, então não precisa instalar Java separado.

---

## 2. Instalar o Flutter SDK

### Opção A — Via `winget` (Recomendado)

```powershell
winget install --id Google.Flutter -e
```

Após a instalação, **feche e reabra o terminal** para atualizar o PATH.

### Opção B — Download manual

1. Acesse: https://docs.flutter.dev/get-started/install/windows/mobile
2. Baixe o arquivo `.zip` da versão **stable** mais recente
3. Extraia para `C:\dev\flutter` (ou o diretório de sua preferência)
4. **Adicione ao PATH do sistema:**

```powershell
# Abra as Configurações do Sistema → Variáveis de Ambiente
# Adicione à variável PATH:
C:\dev\flutter\bin
```

5. **Feche e reabra o terminal.**

### Verificar instalação

```powershell
flutter --version
```

Deve exibir algo como:
```
Flutter 3.x.x • channel stable
Dart SDK version: 3.x.x
```

---

## 3. Instalar o Android Studio

O Android Studio é necessário para o Android SDK, emuladores e build tools.

### Download

1. Acesse: https://developer.android.com/studio
2. Baixe o instalador para Windows
3. Execute o instalador e siga as etapas:
   - ✅ Marque **"Android SDK"**
   - ✅ Marque **"Android SDK Platform"**
   - ✅ Marque **"Android Virtual Device"** (emulador)
4. Anote o caminho do SDK (padrão: `C:\Users\<seu-usuario>\AppData\Local\Android\Sdk`)

### Instalar Plugins do Flutter

1. Abra o **Android Studio**
2. Vá em **Plugins** (tela inicial ou `File → Settings → Plugins`)
3. Busque e instale:
   - **Flutter** (inclui o Dart automaticamente)
4. Reinicie o Android Studio

---

## 4. Configurar o Android SDK

Dentro do Android Studio:

1. Abra **Settings** → **Languages & Frameworks** → **Android SDK**
2. Na aba **SDK Platforms**, marque:
   - ✅ **Android 14.0 (API 34)** — ou a versão mais recente disponível
3. Na aba **SDK Tools**, marque:
   - ✅ Android SDK Build-Tools
   - ✅ Android SDK Command-line Tools
   - ✅ Android SDK Platform-Tools
   - ✅ Android Emulator
4. Clique em **Apply** e aguarde o download

### Configurar variáveis de ambiente

Adicione estas variáveis de ambiente do sistema:

```powershell
# Abra PowerShell como Administrador e execute:
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "$env:LOCALAPPDATA\Android\Sdk", "User")

# Adicione ao PATH:
# %LOCALAPPDATA%\Android\Sdk\platform-tools
# %LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin
```

**Feche e reabra o terminal** após configurar.

---

## 5. Aceitar as Licenças do Android

```powershell
flutter doctor --android-licenses
```

Aceite todas as licenças digitando `y` quando solicitado.

---

## 6. Verificar a Instalação (flutter doctor)

```powershell
flutter doctor -v
```

**Resultado esperado:** Todos os itens com ✅ (check verde):

```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Windows Version (Windows 10/11)
[✓] Android toolchain - develop for Android devices (API 34)
[✓] Android Studio (version 2024.x.x)
[✓] Connected device (1 available)  ← aparece se um celular estiver conectado
```

> Se algum item estiver com ✗ ou !, siga as instruções que o `flutter doctor` mostra.

---

## 7. Inicializar o Projeto Flutter

Abra o terminal na pasta do projeto e execute:

```powershell
cd "c:\Users\ferna\Desktop\EFICEM\Projeto Celular"
flutter create --project-name eficem_pilot --org com.eficem --platforms android .
```

> ⚠️ **IMPORTANTE:** O ponto final (`.`) indica que o projeto será criado **no diretório atual**. O Flutter vai gerar as pastas `android/`, `test/`, etc. sem sobrescrever os arquivos `lib/` e `pubspec.yaml` que já existem.

Caso o Flutter pergunte se deseja sobrescrever arquivos existentes:
- **pubspec.yaml** → Responda **N** (não sobrescrever — o nosso já está configurado)
- **lib/main.dart** → Responda **N** (não sobrescrever — o nosso já está configurado)
- **Outros arquivos** → Responda **Y** (deixar o Flutter gerar)

---

## 8. Baixar as Fontes

O app usa a fonte **Rajdhani** (estilo racing/tech). É necessário baixar manualmente:

1. Acesse: https://fonts.google.com/specimen/Rajdhani
2. Clique em **"Download family"**
3. Extraia o ZIP e copie estes arquivos para `assets/fonts/`:

```
assets/fonts/
├── Rajdhani-Regular.ttf
├── Rajdhani-Medium.ttf
├── Rajdhani-SemiBold.ttf
└── Rajdhani-Bold.ttf
```

---

## 9. Instalar as Dependências

```powershell
cd "c:\Users\ferna\Desktop\EFICEM\Projeto Celular"
flutter pub get
```

Isso vai baixar todas as bibliotecas listadas no `pubspec.yaml`:

| Pacote | Versão | Função |
|--------|--------|--------|
| `flutter_riverpod` | ^3.3.1 | Gerenciamento de estado (providers) |
| `flutter_blue_plus` | ^1.34.5 | Conexão Bluetooth BLE com o ESP32 |
| `mqtt_client` | ^10.11.9 | Publicação MQTT para o dashboard |
| `sqflite` | ^2.4.1 | Buffer local SQLite (resiliência) |
| `google_fonts` | ^6.2.1 | Fontes do Google (fallback) |
| `wakelock_plus` | ^1.3.1 | Manter tela ligada |
| `connectivity_plus` | ^6.1.4 | Verificar conectividade de rede |
| `permission_handler` | ^11.4.0 | Solicitar permissões (BLE, localização) |

---

## 10. Executar o App

### Com celular Android conectado via USB

1. Ative o **Modo Desenvolvedor** no celular:
   - `Configurações → Sobre o telefone → Número da versão` (toque 7x)
2. Ative a **Depuração USB**:
   - `Configurações → Opções do desenvolvedor → Depuração USB`
3. Conecte o celular via cabo USB
4. Verifique se foi detectado:

```powershell
flutter devices
```

5. Execute o app:

```powershell
flutter run
```

### Com emulador Android

1. Abra o **Android Studio** → **Device Manager**
2. Crie um emulador (ex: Pixel 7, API 34)
3. Inicie o emulador
4. Execute:

```powershell
flutter run
```

### Build do APK (para instalar no celular do piloto)

```powershell
flutter build apk --release
```

O APK será gerado em: `build/app/outputs/flutter-apk/app-release.apk`

---

## 11. Estrutura do Projeto

```
Projeto Celular/
├── pubspec.yaml                    # Manifest: dependências e config
├── analysis_options.yaml           # Regras de lint do Dart
├── .gitignore                      # Arquivos ignorados pelo Git
│
├── lib/                            # Código-fonte Dart
│   ├── main.dart                   # Entry point: landscape, fullscreen, wakelock
│   │
│   ├── core/                       # Configurações globais
│   │   ├── constants.dart          # UUIDs BLE, configs MQTT, constantes
│   │   └── theme/
│   │       └── app_theme.dart      # Dark theme racing (cores, fontes, estilos)
│   │
│   ├── models/                     # Modelos de dados
│   │   └── telemetry_packet.dart   # Pacote de telemetria (JSON + BLE bytes)
│   │
│   ├── services/                   # Camada de comunicação
│   │   ├── ble_service.dart        # Scan, connect, subscribe BLE → ESP32
│   │   └── mqtt_service.dart       # Publish MQTT → Notebook (Mosquitto)
│   │
│   ├── providers/                  # Riverpod state management
│   │   └── telemetry_provider.dart # Bridge BLE→MQTT, estado central do app
│   │
│   ├── screens/                    # Telas
│   │   └── dashboard_screen.dart   # Tela principal do piloto
│   │
│   └── widgets/                    # Componentes visuais reutilizáveis
│       ├── speed_gauge.dart        # Velocímetro com arco animado
│       ├── power_gauge.dart        # Gauge de consumo com cores dinâmicas
│       ├── connection_status_bar.dart  # Barra de status BLE/MQTT/Volta
│       └── session_alert.dart      # Overlay de troca de volta
│
├── assets/                         # Recursos estáticos
│   ├── icons/                      # Ícones SVG
│   └── fonts/                      # Fontes Rajdhani (.ttf)
│
├── android/                        # [Gerado pelo Flutter] Config Android nativa
├── test/                           # [Gerado pelo Flutter] Testes unitários
└── build/                          # [Gerado pelo Flutter] Artefatos de build
```

---

## 12. Solução de Problemas

### `flutter doctor` mostra erro de Android toolchain

```powershell
# Verifique se o ANDROID_HOME está configurado:
echo $env:ANDROID_HOME

# Se estiver vazio, configure:
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")
```

### Erro de permissão BLE no Android

O `flutter_blue_plus` precisa destas permissões no `AndroidManifest.xml`. Elas já são adicionadas automaticamente pelo plugin, mas se houver erro, verifique em `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### Erro `minSdkVersion` no build

Edite `android/app/build.gradle` e altere:

```gradle
defaultConfig {
    minSdk = 21    // Mínimo para BLE
    // ou minSdkVersion 21
}
```

### Celular não detectado pelo `flutter devices`

1. Verifique se a **Depuração USB** está ativada
2. Se aparecer popup "Confiar neste computador?" no celular, aceite
3. Teste com: `adb devices` (deve mostrar o serial do celular)
4. Reinstale drivers USB do fabricante do celular se necessário

### Erro de `wakelock_plus` no emulador

O wakelock pode falhar no emulador (normal). Para testar no emulador, comente temporariamente a linha `WakelockPlus.enable()` em `main.dart`.

### Fonts não carregam

Verifique que os arquivos `.ttf` estão em `assets/fonts/` com os nomes exatos:
- `Rajdhani-Regular.ttf`
- `Rajdhani-Medium.ttf`
- `Rajdhani-SemiBold.ttf`
- `Rajdhani-Bold.ttf`

Depois rode `flutter pub get` novamente.

---

## Checklist Rápido

- [ ] Flutter SDK instalado e no PATH
- [ ] Android Studio instalado com SDK e plugins
- [ ] Licenças Android aceitas (`flutter doctor --android-licenses`)
- [ ] `flutter doctor` sem erros
- [ ] `flutter create` executado na pasta do projeto
- [ ] Fontes Rajdhani em `assets/fonts/`
- [ ] `flutter pub get` executado com sucesso
- [ ] App roda no celular ou emulador (`flutter run`)

---

> **Próximos passos após o setup:**
> - Conectar ao ESP32-S3 via BLE (requer firmware do ESP rodando)
> - Configurar IP do notebook no app (menu Settings → IP do MQTT broker)
> - Testar fluxo completo: ESP → BLE → App → MQTT → Dashboard
