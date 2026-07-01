# FinanceHub

FinanceHub é um protótipo de aplicativo Flutter para controle de finanças pessoais. O app permite cadastrar receitas e despesas, organizar transações por categorias, acompanhar gráficos no dashboard e consultar cotações de moedas em tempo real.

## Funcionalidades

- Cadastro e login de usuários com Firebase Authentication.
- Persistência de dados no Cloud Firestore por usuário autenticado.
- Cadastro, edição, listagem e exclusão de transações.
- Cadastro e gerenciamento de categorias.
- Dashboard com resumo de entradas, saídas, saldo e gráficos.
- Gráfico de despesas por categoria usando `fl_chart`.
- Busca, filtros e ordenação de transações.
- Rolagem infinita na lista de transações.
- Seleção de local da transação com mapa e geolocalização.
- Consulta de cotações de Dólar, Euro e Bitcoin em Real usando AwesomeAPI.
- Preferências locais com `shared_preferences`, como tema e filtros.
- Suporte a tema claro e escuro.

## Tecnologias

- Flutter
- Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Shared Preferences
- fl_chart
- flutter_map
- geolocator
- http
- AwesomeAPI para cotações

## Estrutura do Projeto

```text
lib/
  controllers/    Regras de estado e controle das telas
  models/         Modelos de dados da aplicação
  pages/          Telas principais do app
  repositories/   Acesso ao Firestore
  services/       Serviços locais e integrações externas
  widgets/        Componentes reutilizáveis de interface
```

## Firebase

O app usa Firebase para autenticação e armazenamento remoto.

Os dados são organizados por usuário:

```text
users/{uid}/transactions/{transactionId}
users/{uid}/categories/{categoryId}
```

As regras do Firestore garantem que cada usuário acesse apenas os próprios dados:

```js
match /users/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

## Como Executar

1. Instale as dependências:

```bash
flutter pub get
```

2. Execute o app:

```bash
flutter run
```

## Requisitos Atendidos

- Projeto estruturado em pastas por responsabilidade.
- Navegação entre mais de três páginas.
- Uso de `StatelessWidget` e `StatefulWidget`.
- Formulários com validação.
- Eventos enviados por widgets filhos via callbacks.
- Consumo de API externa.
- Armazenamento local no dispositivo.
- Armazenamento remoto com Firestore.
- Recurso nativo de geolocalização.
- Rolagem infinita.
- Animação no ticker de cotações.