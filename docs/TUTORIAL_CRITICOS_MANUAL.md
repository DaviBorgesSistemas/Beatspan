# Tutorial: como fazer manualmente os itens críticos já concluídos

**Projeto:** Beatspan
**Referência:** itens críticos de [4-ACTION_PLAN.md](4-ACTION_PLAN.md) já marcados `[x]`
**Objetivo:** explicar passo a passo como qualquer um desses itens seria feito à mão, sem IA, para quem for reproduzir, revisar ou ensinar o processo.

---

## 1. Remover `.env` do controle de versão `[SEC-001]`

**Problema:** o arquivo `.env` (com credenciais do Spotify) estava versionado no Git, sem estar no `.gitignore`.

### Passo a passo

1. Abra o `.gitignore` na raiz do projeto e adicione uma linha com `.env`.
2. Remova o arquivo do índice do Git, mas mantenha-o no disco:
   ```bash
   git rm --cached .env
   ```
3. Confirme que ele não aparece mais rastreado:
   ```bash
   git ls-files | grep .env
   # não deve retornar nada
   ```
4. Crie um `.env.example` (sem valores reais) para documentar o formato esperado:
   ```
   SPOTIFY_CLIENT_ID=
   SPOTIFY_REDIRECT_URL=
   ```
5. Commit:
   ```bash
   git add .gitignore .env.example
   git commit -m "security: remove .env do controle de versão"
   ```
6. **Rotacionar a credencial** (etapa que ainda falta neste projeto): acesse o [Spotify Developer Dashboard](https://developer.spotify.com/dashboard), abra o app registrado, gere um novo Client ID (ou regenere o secret associado) e atualize o valor no seu `.env` local e em qualquer lugar que o consome.

> **Nota sobre este projeto:** como o repositório é privado, foi decidido posteriormente reintroduzir o `.env` versionado por conveniência — uma escolha válida para um repo privado, mas que reabre a exposição do valor no histórico do Git caso o repositório mude de visibilidade no futuro.

---

## 2. Migrar credenciais hardcoded para `.env` via `flutter_dotenv` `[SEC-002 / ARQ-009]`

**Problema:** o Client ID e o Redirect URL do Spotify estavam como string literal direto no código (`lib/app/di.dart`), em vez de vir de configuração externa.

### Passo a passo

1. Adicione a dependência no `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_dotenv: ^5.2.1
   ```
2. Registre o `.env` como asset, também no `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - .env
   ```
3. Rode `flutter pub get`.
4. No ponto de entrada do app (`lib/main.dart`), carregue o `.env` **antes** de qualquer código que precise dele:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await dotenv.load(fileName: '.env');
     // ... resto da inicialização
   }
   ```
5. No local onde a credencial era usada (`lib/app/di.dart`), troque o literal por leitura do `dotenv.env`:
   ```dart
   final clientId = dotenv.env['SPOTIFY_CLIENT_ID'];
   final redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL'];
   ```
6. Adicione uma validação que falhe de forma clara se a variável não existir, em vez de seguir silenciosamente com `null`/string vazia:
   ```dart
   String _requiredEnv(String key) {
     final value = dotenv.env[key];
     if (value == null || value.isEmpty) {
       throw StateError(
         'Variável de ambiente "$key" não definida. Copie .env.example '
         'para .env e preencha os valores antes de rodar o app.',
       );
     }
     return value;
   }
   ```
7. Valide rodando:
   ```bash
   flutter analyze
   flutter test
   flutter build apk --debug
   ```
8. Confirme visualmente que não sobrou nenhum literal de credencial no código:
   ```bash
   grep -rn "8e1f4c38" lib/   # (ou o padrão do seu Client ID antigo)
   # não deve retornar nada
   ```

---

## 3. Criar um pipeline de CI mínimo `[OPS-002]`

**Problema:** não havia nenhuma automação rodando `flutter analyze`/`flutter test` a cada mudança — bugs só eram descobertos manualmente.

### Passo a passo

1. Descubra a versão exata do Flutter usada localmente, para fixar a mesma no CI:
   ```bash
   flutter --version
   ```
2. Crie a pasta `.github/workflows/` na raiz do repositório.
3. Dentro dela, crie um arquivo `ci.yml`:
   ```yaml
   name: CI

   on:
     pull_request:
       branches: ["**"]
     push:
       branches: [master]

   jobs:
     analyze-and-test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4

         - uses: subosito/flutter-action@v2
           with:
             flutter-version: "3.35.7"   # a versão que você descobriu no passo 1
             channel: "stable"
             cache: true

         - name: Instalar dependências
           run: flutter pub get

         - name: Analisar
           run: flutter analyze --fatal-infos

         - name: Verificar formatação
           run: dart format --output=none --set-exit-if-changed .

         - name: Rodar testes
           run: flutter test
   ```
4. **Importante:** antes de commitar, rode os mesmos 3 comandos localmente para garantir que o pipeline vai passar de primeira:
   ```bash
   flutter analyze --fatal-infos
   dart format --output=none --set-exit-if-changed .
   flutter test
   ```
5. Se o passo de formatação falhar em arquivos que você não tocou, rode `dart format .` no projeto inteiro num commit isolado (só formatação, sem lógica), para não misturar uma reformatação grande com uma mudança funcional.
6. Commit e push. Abra um Pull Request de teste para confirmar que o workflow dispara e aparece o resultado (✅/❌) na aba "Checks" do GitHub.

---

## 4. Escrever a primeira leva de testes unitários `[OPS-001]`

**Problema:** zero testes automatizados no projeto inteiro — nenhuma pasta `test/`.

### Passo a passo

1. Escolha componentes de **lógica pura**, sem dependência de UI ou de plugins nativos, para começar — são os mais baratos de testar e os que dão mais confiança rápido. Neste projeto: parsing de URL do QR code, e o par Repository/UseCase que fala com o Firestore.
2. Crie a estrutura de pastas em `test/` espelhando `lib/`:
   ```
   test/
   ├── presentation/game/game_viewmodel_test.dart
   ├── data/repository/musica_repository_impl_test.dart
   └── domain/usecase/get_musica_usecase_test.dart
   ```
3. Para testar uma classe pura sem dependências (ex.: `GameViewModel`), basta instanciar e testar diretamente:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:beatspan/presentation/game/game_viewmodel.dart';

   void main() {
     late GameViewModel viewModel;

     setUp(() => viewModel = GameViewModel());

     test('extrai o código de uma URL válida', () {
       expect(
         viewModel.extractCodigo('https://beatspangame.com/0006'),
         '0006',
       );
     });
   }
   ```
4. Para testar uma classe com dependências (ex.: um Repository que depende de um data source), adicione uma lib de mock:
   ```yaml
   dev_dependencies:
     mocktail: ^1.0.4
   ```
   E crie um mock da dependência:
   ```dart
   import 'package:mocktail/mocktail.dart';

   class _MockMusicaFirestoreDataSource extends Mock
       implements MusicaFirestoreDataSource {}

   void main() {
     late _MockMusicaFirestoreDataSource dataSource;
     late MusicaRepositoryImpl repository;

     setUp(() {
       dataSource = _MockMusicaFirestoreDataSource();
       repository = MusicaRepositoryImpl(dataSource);
     });

     test('retorna Left(Failure(404)) quando não encontra a música', () async {
       when(() => dataSource.getByCodigo('9999'))
           .thenThrow(MusicaNaoEncontradaException('9999'));

       final result = await repository.getByCodigo('9999');

       expect(result.isLeft(), isTrue);
       result.fold(
         (failure) => expect(failure.code, 404),
         (_) => fail('esperava Left'),
       );
     });
   }
   ```
5. Rode a suíte inteira e confirme que tudo passa:
   ```bash
   flutter test
   ```
6. Cubra pelo menos: o caminho feliz, um erro esperado/tratado (ex.: "não encontrado"), e um erro inesperado (ex.: falha de rede genérica) — isso já dá cobertura das 3 ramificações mais importantes de qualquer função que trata erro.

---

## 5. Integrar Firebase Crashlytics `[OPS-003]`

**Problema:** nenhuma ferramenta captura crashes/exceções não tratadas em produção — se o app falhasse para um usuário, ninguém saberia.

### Passo a passo

#### Parte A — código (Flutter/Dart)

1. Adicione a dependência:
   ```yaml
   dependencies:
     firebase_crashlytics: ^4.1.5
   ```
2. Rode `flutter pub get`.
3. No Android, registre o plugin Gradle do Crashlytics. No `android/settings.gradle.kts`, dentro do bloco `plugins`:
   ```kotlin
   id("com.google.firebase.crashlytics") version("3.0.2") apply false
   ```
4. No `android/app/build.gradle.kts`, dentro do bloco `plugins`:
   ```kotlin
   id("com.google.firebase.crashlytics")
   ```
5. **Atenção a versões:** o Crashlytics Gradle plugin v3 exige `google-services` 4.4.1 ou superior. Se o projeto estiver numa versão mais antiga, atualize em `android/settings.gradle.kts`:
   ```kotlin
   id("com.google.gms.google-services") version("4.4.2") apply false
   ```
6. No `lib/main.dart`, capture os dois tipos de erro que o Flutter não pega sozinho — erros de framework e erros assíncronos fora da árvore de widgets:
   ```dart
   import 'dart:async';
   import 'package:firebase_crashlytics/firebase_crashlytics.dart';
   import 'package:flutter/foundation.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();

     await runZonedGuarded(
       () async {
         // ... inicialização normal do Firebase/app ...

         await FirebaseCrashlytics.instance
             .setCrashlyticsCollectionEnabled(!kDebugMode);

         FlutterError.onError = (details) {
           FlutterError.presentError(details);
           FirebaseCrashlytics.instance.recordFlutterFatalError(details);
         };

         PlatformDispatcher.instance.onError = (error, stackTrace) {
           FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
           return true;
         };

         runApp(MyApp());
       },
       (error, stackTrace) {
         // erros assíncronos fora da árvore de widgets (ex.: Future sem catch)
         FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
       },
     );
   }
   ```
   > Desabilitar a coleta em `kDebugMode` evita poluir o dashboard com erros do seu próprio ambiente de desenvolvimento local.
7. Valide que o build ainda funciona, **incluindo o release** (é onde a minificação/R8 costuma quebrar integrações novas):
   ```bash
   flutter build apk --debug
   flutter build apk --release
   ```

#### Parte B — Firebase Console (não dá para automatizar por código)

8. Acesse o [Firebase Console](https://console.firebase.google.com/) → selecione o projeto → menu lateral **Crashlytics**.
9. Clique em **"Ativar Crashlytics"** (ou "Enable Crashlytics") para o app Android registrado.
10. **Simule um crash de teste** para confirmar que a integração está funcionando de ponta a ponta. A forma mais simples: adicione um botão temporário em qualquer tela que force um erro, por exemplo:
    ```dart
    ElevatedButton(
      onPressed: () => throw Exception('Teste de crash do Crashlytics'),
      child: const Text('Forçar crash de teste'),
    )
    ```
11. Rode o app em modo **release** (não debug — lembre que a coleta foi desabilitada em debug no passo 6) num dispositivo físico ou emulador, toque no botão, e feche o app.
12. Volte ao Firebase Console → Crashlytics. Pode levar alguns minutos para o crash aparecer na primeira vez. Confirme que ele aparece listado com stack trace.
13. Remova o botão de teste do código antes de mergear/publicar.

---

## Resumo do que cada item exige de você (fora de código)

| Item | Ação manual pendente fora do código |
|---|---|
| SEC-001 | Rotacionar a credencial no Spotify Developer Dashboard |
| SEC-002/ARQ-009 | Nenhuma — só rodar o app com o `.env` preenchido |
| OPS-002 | Nenhuma — só abrir um PR de teste para ver o CI rodar |
| OPS-001 | Nenhuma — testes já rodam localmente e em CI |
| OPS-003 | Habilitar o Crashlytics no Firebase Console + simular 1 crash de teste |
