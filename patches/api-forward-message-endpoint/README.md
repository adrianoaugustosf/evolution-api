# api-forward-message-endpoint

## Objetivo
Adicionar o endpoint `POST /message/forwardMessage/:instanceName` na Evolution API para encaminhar uma mensagem existente preservando os metadados de forward do Baileys.

## Origem
- Commit base do patch: `b6b5529f`
- Fork: `adrianoaugustosf/evolution-api`

## Arquivos afetados
- `src/api/routes/sendMessage.router.ts`
- `src/api/controllers/sendMessage.controller.ts`
- `src/api/dto/sendMessage.dto.ts`
- `src/validate/message.schema.ts`
- `src/api/integrations/channel/whatsapp/whatsapp.baileys.service.ts`

## O que o patch faz
- adiciona DTO para o payload de encaminhamento
- adiciona schema de validacao para `forwarding.key`
- adiciona rota `forwardMessage` no router de mensagens
- adiciona controller `forwardMessage`
- implementa o fluxo de forward no service Baileys usando `generateForwardMessageContent`

## Endpoint
`POST /message/forwardMessage/:instanceName`

Payload de exemplo em [request-example.json](./request-example.json).

## Reaplicacao apos update do upstream
1. Atualize o fork normalmente.
2. Se o commit customizado nao estiver presente ou se houver conflito, aplique o patch:
   ```powershell
   git apply --3way .\patches\api-forward-message-endpoint\api-forward-message-endpoint.patch
   ```
3. Gere o Prisma Client conforme o provider usado no ambiente. Exemplo para PostgreSQL:
   ```powershell
   $env:DATABASE_PROVIDER='postgresql'
   npm.cmd run db:generate
   ```
4. Valide build:
   ```powershell
   npm.cmd run build
   ```

## Observacoes
- O endpoint depende de a mensagem original existir no store da instancia.
- Quando a mensagem nao e encontrada, a resposta esperada e `404` com `Message not found in store`.
- O projeto Docker `bigoffer-evolution-docker` builda este fork localmente a partir de `../evolution-api`.
