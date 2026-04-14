# Patches

Este diretorio concentra customizacoes locais mantidas no fork da Evolution API.

## Patches ativos

### api-forward-message-endpoint
- Objetivo: adicionar o endpoint `POST /message/forwardMessage/:instanceName`.
- Escopo: rota, controller, DTO, schema e service Baileys.
- Pasta: [api-forward-message-endpoint](./api-forward-message-endpoint)
- Reaplicacao: usar `git apply --3way` com o arquivo `api-forward-message-endpoint.patch` e depois validar `db:generate` + `build`.
