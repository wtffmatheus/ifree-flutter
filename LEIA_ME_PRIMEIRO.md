# iFree v2.0 — Guia Completo de Configuração

## ✅ Problemas corrigidos

| # | Problema | Solução |
|---|----------|---------|
| 1 | **Página inicial:** "Bad state: cannot get field 'name' on a DocumentSnapshot which does not exist" | Adicionado `snap.data!.exists` antes de ler campos. Nunca mais crasha. |
| 2 | **Login Google no Chrome:** "ClientID not set..." | Adicionar `<meta name="google-signin-client_id">` em `web/index.html` (instruções abaixo). |
| 3 | **Meus Jobs:** loading infinito | Trocado `collectionGroup('candidaturas')` por `users/{uid}/candidaturas_index` — query simples, sem índice composto necessário. |
| 4 | **Botão Sair:** não funcionava | `AuthRepository.signOut()` agora chama `_googleSignIn.signOut()` + `_auth.signOut()` em try/catch separados. |
| 5 | **Modo noturno:** estava na AppBar | Removido da AppBar. Agora está em **Perfil → Configurações → Modo noturno**. |
| 6 | **Perfil:** básico demais, abria em edição direto | Agora tem **view mode** com avatar, stats, avaliações, habilidades, configurações. Edição só ao clicar "✏ Editar perfil". |
| 7 | **Vagas:** sem localização real | Vagas com `lat`/`lng` reais de Sorocaba. Ordenadas por distância do usuário. Badge mostra distância em km. |

---

## 🔧 Configuração passo a passo

### 1. Google Login no Chrome Web (OBRIGATÓRIO)

1. Acesse https://console.cloud.google.com
2. Selecione seu projeto Firebase
3. Vá em **APIs & Services → Credentials**
4. Em **OAuth 2.0 Client IDs**, abra o ID do tipo "Web application"
5. Copie o valor (termina em `.apps.googleusercontent.com`)
6. Cole no arquivo `web/index.html`:
```html
<meta name="google-signin-client_id" content="COLE_AQUI.apps.googleusercontent.com">
```

### 2. Seed de vagas fictícias (Sorocaba)

Execute **uma única vez** em modo debug para popular o Firestore:

```dart
// Em main.dart, dentro do main(), APÓS Firebase.initializeApp():
if (kDebugMode) {
  await SeedData.run(); // ← adicione isso
}
```

Isso cria 8 vagas reais de Sorocaba com lat/lng + avaliações e jobs para `user.matheus169@gmail.com`.

**Depois de rodar, remova a linha para não duplicar.**

### 3. UID real do Matheus

Para os dados fictícios aparecerem no perfil do Matheus:

1. Faça login com `user.matheus169@gmail.com`
2. Copie o UID do Firebase Auth Console (ou print no console: `print(FirebaseAuth.instance.currentUser!.uid)`)
3. No `seed_data.dart`, substitua:
```dart
final matheusUid = 'matheus169_uid'; // ← substitua pelo UID real
```

### 4. Índice do Firestore (candidaturas_index)

Para que o `StreamBuilder` de Meus Jobs funcione com `orderBy`:

No **Firebase Console → Firestore → Indexes → Composite**, crie:
- Collection: `candidaturas_index`
- Fields: `status ASC`, `appliedAt DESC`
- Query scope: Collection

Ou rode o app uma vez — o Firebase mostrará o link para criar o índice automaticamente no console de erros.

---

## 🚀 Novas funcionalidades v2.0

- **Vagas ordenadas por distância** com badge "X km" em verde/amarelo/cinza
- **Botão GPS** na busca para usar localização atual
- **Categorias rápidas** na home (Bartender, Chef, Barista, etc.)
- **Stats na home** (Jobs feitos, Avaliação, Vagas hoje)
- **Perfil rico**: view mode com avaliações dos restaurantes, habilidades, stats
- **Configurações no perfil**: modo noturno, notificações, privacidade, logout
- **Candidatos**: exibe bio e avaliação do freelancer para o restaurante
- **Shimmer loading** em todas as listas
- **Erros Firebase** traduzidos para português
- **Tema persistido** no SharedPreferences (lembrado entre sessões)

---

## 📁 Estrutura de arquivos novos/modificados

```
lib/
├── main.dart                          ← ThemeModeNotifier corrigido
├── core/
│   ├── theme/
│   │   ├── app_colors.dart            ← paleta completa dark/light
│   │   └── app_theme.dart             ← tema premium Sora font
│   ├── router/app_router.dart         ← rotas com ShellRoute
│   ├── utils/
│   │   ├── location_helper.dart       ← GPS + distância km
│   │   └── seed_data.dart             ← vagas fictícias Sorocaba
│   └── widgets/app_widgets.dart       ← ShimmerCard, IFreeAvatar, StatusBadge, etc.
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart  ← signOut corrigido
│   │   └── presentation/
│   │       ├── auth_page.dart         ← design premium, erros traduzidos
│   │       └── forgot_password_screen.dart
│   ├── freelancer/presentation/
│   │   ├── freelancer_dashboard.dart  ← home premium com distância
│   │   ├── job_search_screen.dart     ← filtros + ordenação GPS
│   │   ├── my_jobs_page.dart          ← CORRIGIDO loading infinito
│   │   └── profile_freelancer_page.dart ← perfil rico + configs
│   └── restaurant/presentation/
│       ├── company_dashboard.dart     ← melhorado
│       ├── candidates_screen.dart     ← mostra bio/rating + atualiza índice
│       ├── create_vacancy_screen.dart ← original mantido
│       └── profile_restaurant_page.dart ← original mantido
└── web/index.html                     ← meta google-signin-client_id
```
