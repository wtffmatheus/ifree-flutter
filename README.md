# iFree App

Aplicativo Flutter/Firebase para conectar **freelancers** e **restaurantes/empresas** em vagas de diária.

## Resumo do projeto

O iFree permite que empresas publiquem vagas temporárias e freelancers encontrem oportunidades, candidatem-se e acompanhem o status pelo app.

Durante a melhoria do projeto, foram trabalhados:

- Login/cadastro com Firebase Auth.
- Separação de fluxo para freelancer e empresa.
- Perfil do freelancer com foto, informações profissionais, habilidades, avaliações e alternância de tema claro/escuro.
- Perfil da empresa com logo/foto, dados do estabelecimento e informações de contato.
- Criação de vagas reais pela empresa.
- Busca de vagas reais pelo freelancer.
- Candidatura real em vagas.
- Tela “Meus Jobs” para acompanhar candidaturas.
- Aprovação/recusa de candidatos pela empresa.
- Cancelamento de candidatura pelo freelancer.
- Cancelamento/finalização de vaga pela empresa.
- Notificações internas no Firestore.
- Painéis com estatísticas reais para freelancer e empresa.
- Correções em regras do Firestore para permitir o fluxo real.
- Remoção de dependência do Firebase Storage para foto, usando `image_picker` + base64 no Firestore para evitar cobrança/billing.
- Melhorias visuais em cards, botões, filtros, dashboards e perfis.

## Funcionalidades principais

### Freelancer

- Visualizar vagas ativas.
- Filtrar vagas por categoria.
- Ver detalhes de uma vaga.
- Candidatar-se a uma vaga.
- Cancelar candidatura quando ainda não aprovada.
- Acompanhar status em “Meus Jobs”.
- Receber notificações internas.
- Editar perfil.
- Adicionar foto direto do dispositivo.
- Visualizar avaliações e total de jobs.

### Empresa

- Criar vaga com validações.
- Ver vagas publicadas.
- Ver candidatos por vaga.
- Ver perfil completo do candidato.
- Aprovar ou recusar candidato.
- Abrir chat com candidato.
- Finalizar job e avaliar freelancer.
- Cancelar vaga.
- Receber notificações internas.
- Editar perfil da empresa.

### Administração

Foi adicionada uma tela inicial de painel administrativo para consulta geral:

- Total de usuários.
- Total de vagas.
- Vagas ativas.
- Candidaturas.
- Últimos usuários cadastrados.
- Últimas vagas publicadas.

Para acessar o painel administrativo, o usuário precisa ter no Firestore:

```txt
users/{uid}.role = "admin"
```

## Estrutura importante

```txt
lib/
  core/
    utils/
      app_validators.dart
  features/
    admin/
      presentation/
        admin_dashboard_page.dart
    chat/
      data/
        chat_repository.dart
      presentation/
        chat_page.dart
    jobs/
      data/
        vaga_repository.dart
    freelancer/
      presentation/
        job_search_screen.dart
        my_jobs_page.dart
        profile_freelancer_page.dart
    restaurant/
      presentation/
        company_dashboard.dart
        candidates_screen.dart
        create_vacancy_screen.dart
        profile_restaurant_page.dart
```

## Dependências

No `pubspec.yaml`, confirme pelo menos:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  flutter_riverpod: ^2.0.0
  go_router: ^14.0.0
  image_picker: ^1.1.2
```

> Observação: `firebase_storage` não é obrigatório nesta versão, porque a foto foi adaptada para base64 no Firestore.

## Como rodar

Na raiz do projeto:

```powershell
flutter pub get
flutter analyze
firebase deploy --only firestore --project ifree-ab709
flutter run -d chrome --web-port 5000
```

## Rotas que precisam existir

No `app_router.dart`, confirme/adapte rotas parecidas com:

```dart
GoRoute(
  path: '/notifications',
  builder: (context, state) => const NotificationsPage(),
),

GoRoute(
  path: '/admin',
  builder: (context, state) => const AdminDashboardPage(),
),
```

Para chat, se quiser usar rota:

```dart
GoRoute(
  path: '/chat',
  builder: (context, state) {
    final conversationId = state.uri.queryParameters['conversationId']!;
    final title = state.uri.queryParameters['title'] ?? 'Chat';

    return ChatPage(
      conversationId: conversationId,
      title: title,
    );
  },
),
```

Neste pacote, a tela de candidatos já abre o chat por `Navigator.push`, então a rota `/chat` é opcional.

## Fluxo de teste recomendado

### 1. Empresa cria vaga

1. Entrar com conta empresa.
2. Completar perfil da empresa.
3. Criar uma vaga.
4. Conferir se aparece no painel da empresa.

### 2. Freelancer se candidata

1. Entrar com conta freelancer.
2. Abrir “Buscar”.
3. Ver detalhes da vaga.
4. Candidatar-se.
5. Conferir em “Meus Jobs”.

### 3. Empresa aprova candidato

1. Entrar novamente com a empresa.
2. Abrir candidatos da vaga.
3. Ver perfil completo do candidato.
4. Aprovar candidato.
5. Conferir notificação no freelancer.

### 4. Empresa finaliza job e avalia

1. Na tela de candidatos, após aprovar, clicar em “Finalizar e avaliar”.
2. Informar nota e comentário.
3. Conferir no perfil do freelancer se a avaliação apareceu.

### 5. Cancelamentos

- Freelancer: `Meus Jobs > Cancelar candidatura`.
- Empresa: `Painel da empresa > Cancelar vaga`.

## O que foi feito para deixar o projeto mais completo

- Dados reais no lugar de simulações.
- Botões de confirmação antes de ações importantes.
- Regras do Firestore mais organizadas.
- Notificações internas.
- Chat básico por vaga/candidato.
- Avaliação real após job finalizado.
- Painel administrativo inicial.
- Validações melhores no cadastro de vaga.
- README de execução e apresentação.

## O que ainda pode melhorar

Para uma versão mais profissional, ainda seria interessante:

- Upload real de imagem com Firebase Storage, caso o projeto tenha billing liberado.
- Chat com status de leitura.
- Notificações push com Firebase Cloud Messaging.
- Filtro por distância/localização real.
- Histórico financeiro/pagamentos.
- Página pública do perfil do freelancer.
- Painel admin com ações avançadas, como bloquear usuário e moderar vagas.
- Testes automatizados.
- Melhor responsividade para telas muito grandes no Flutter Web.
- Política de privacidade e termos de uso.

## Observações sobre warnings

Alguns warnings do `flutter analyze` podem aparecer como `deprecated_member_use`, principalmente:

- `withOpacity`
- `desiredAccuracy`
- `value` em campos de formulário
- `const` faltando
- import duplicado

Eles não impedem o app de rodar, mas devem ser limpos para acabamento. Este pacote inclui um script em:

```txt
tools/fix_simple_warnings.ps1
```

Ele ajuda a corrigir parte dos warnings simples automaticamente.
