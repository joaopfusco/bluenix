# Bluenix — Bluefin com Nix

Guia completo para buildar e publicar uma imagem customizada do Bluefin com o Nix pré-instalado via [Determinate Nix](https://determinate.systems/).

---

## Como funciona

O Nix não é instalado durante o build da imagem — em vez disso, o installer é baixado e salvo em `/nix/determinate-nix-installer.sh`. A instalação real acontece no **primeiro boot** do sistema, quando o systemd está ativo e pode configurar tudo corretamente.

Isso é necessário porque o Determinate Nix no modo `ostree` precisa de systemd rodando para configurar o bind mount de `/nix` em `/var/home/nix`, que é o que garante a persistência entre atualizações.

---

## Pré-requisitos

- Conta no GitHub
- `podman` instalado
- `cosign` instalado (`brew install cosign`)

---

## Passo 1 — Criar o repositório

Acesse https://github.com/ublue-os/image-template e clique em **Use this template** → **Create a new repository**. Dê o nome `bluenix` ao repositório.
---

## Passo 2 — Configurar o Containerfile

Edite o `Containerfile` na raiz do repositório:

```dockerfile
ARG UBRAND=bluefin
ARG UFLAVOR=-dx
ARG USTREAM=stable
ARG SOURCE_IMAGE=${UBRAND}${UFLAVOR}:${USTREAM}

FROM scratch AS ctx
COPY build_files /

FROM ghcr.io/ublue-os/${SOURCE_IMAGE} AS base

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit

RUN bootc container lint
```

E crie o arquivo `build_files/build.sh`:

```bash
#!/bin/bash
set -ouex pipefail

mkdir -p /nix && \
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    -o /nix/determinate-nix-installer.sh && \
    chmod a+rx /nix/determinate-nix-installer.sh
```

Faça commit e push das alterações.

---

## Passo 3 — Configurar o cosign

O cosign assina a imagem para que o `rpm-ostree` possa verificá-la.

```bash
# Gerar o par de chaves (não coloque senha — pressione Enter quando pedir)
cosign generate-key-pair
```

Isso gera dois arquivos: `cosign.key` (privada) e `cosign.pub` (pública).

Adicione a chave privada ao GitHub:

1. Vá em **Settings** → **Secrets and variables** → **Actions**
2. Clique em **New repository secret**
3. Nome: `SIGNING_SECRET`
4. Valor: conteúdo do arquivo `cosign.key` (`cat cosign.key`)

Commite o arquivo `cosign.pub` no repositório:

```bash
git add cosign.pub
git commit -m "add cosign public key"
git push
```

---

## Passo 4 — Habilitar o GitHub Actions

Vá na aba **Actions** do repositório e habilite os workflows. Verifique também em **Settings** → **Actions** → **General** → **Workflow permissions** que está marcado **Read and write permissions**.

---

## Passo 5 — Criar o pacote no GHCR pela primeira vez

O GitHub Actions não consegue criar pacotes novos no GHCR automaticamente — é necessário fazer o primeiro push manualmente.

Gere um Personal Access Token em **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)** marcando `write:packages` e `read:packages`.

```bash
# Build local da imagem
podman build -t bluenix .

# Login no GHCR com o token gerado
export CR_PAT=SEU_TOKEN_AQUI
echo $CR_PAT | podman login ghcr.io -u SEU_USUARIO --password-stdin

# Tag e push para o GHCR
podman tag bluenix ghcr.io/SEU_USUARIO/bluenix:latest
podman push ghcr.io/SEU_USUARIO/bluenix:latest
```

Após o push, configure o pacote no GHCR:

1. Acesse **github.com/SEU_USUARIO** → aba **Packages** → clique em `bluenix`
2. Em **Package settings** → **Change visibility** → marque **Public**
3. Em **Manage Actions access** → mude o role do repositório `bluenix` de **Read** para **Write**

Agora rode o workflow manualmente na aba **Actions** — a partir daqui ele funcionará automaticamente em todos os pushes e rebuilds semanais.

---

## Passo 6 — Rebase no sistema

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/SEU_USUARIO/bluenix:latest
```

Reinicie o sistema. Após o reboot, o Nix será instalado automaticamente no primeiro boot.

---

## Passo 7 — Instalar o Nix (primeiro boot)

Se o Nix não for instalado automaticamente, execute manualmente:

```bash
sudo /nix/determinate-nix-installer.sh install ostree --no-confirm
```

---

## Atualizações

A partir daqui tudo é automático. O GitHub Actions rebuilda a imagem toda semana em cima da versão mais recente do Bluefin, e o sistema recebe as atualizações normalmente. O Nix persiste entre atualizações porque fica em `/var/home/nix`, que não é sobrescrito pelo sistema imutável.