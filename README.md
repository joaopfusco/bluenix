# 🦖 Bluenix ❄️

**Bluefin com o Nix como gerenciador de pacotes principal.**

O [Bluefin](https://projectbluefin.io/) é uma das melhores distribuições Linux para desenvolvedores — baseada no Fedora Silverblue, imutável, polida e com atualizações automáticas. O [Nix](https://nixos.org/) é um dos gerenciadores de pacotes mais poderosos do mundo — com mais de 100 mil pacotes, sempre atualizados, sem conflitos.

O Bluenix une os dois. Um sistema operacional imutável para desenvolvedores — com o poder do Nix.

---

## O que é isso?

O Bluefin removeu o suporte oficial ao Nix. O Bluenix é uma imagem customizada do Bluefin que traz o Nix de volta — instalado automaticamente no primeiro boot via [Determinate Nix](https://determinate.systems/), com integração completa ao GNOME.

Com o Bluenix você tem:

- **Nix** como gerenciador de pacotes principal — instala qualquer coisa com `nix profile add`
- **Apps GUI** aparecem automaticamente no GNOME após a instalação
- **Pacotes unfree** (VSCode, Chrome, Slack, etc) funcionam sem configuração extra
- **nixGL** instalado automaticamente para apps que precisam de aceleração GPU
- **Flatpak e brew** continuam funcionando normalmente
- **Atualizações automáticas** — o sistema se mantém atualizado sem intervenção

---

## Como funciona

O Nix não é instalado durante o build da imagem. Em vez disso, o installer é baixado e salvo em `/nix/determinate-nix-installer.sh`, e a instalação acontece no **primeiro boot** — quando o systemd está ativo e pode configurar tudo corretamente.

Isso é necessário porque o Determinate Nix no modo `ostree` precisa do systemd rodando para configurar o bind mount de `/nix` em `/var/home/nix`, garantindo a persistência entre atualizações da imagem.

Um wrapper transparente substitui o comando `nix` original e automaticamente injeta `--impure` e `NIXPKGS_ALLOW_UNFREE=1` para liberar pacotes proprietários, além de criar symlinks dos arquivos `.desktop` para que apps apareçam no GNOME imediatamente após a instalação.

Para detalhes de implementação, veja o [`Containerfile`](./Containerfile) e o [`build_files/build.sh`](./build_files/build.sh).

---

## Instalação rápida

Se você só quer usar o Bluenix sem buildar sua própria imagem, faça rebase direto:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/joaopfusco/bluenix:latest
```

Reinicie. No primeiro boot o Nix será instalado automaticamente.

> Se o Nix não instalar automaticamente, execute manualmente:
> ```bash
> sudo /nix/determinate-nix-installer.sh install ostree --no-confirm
> ```

---

## Uso

Instalar qualquer pacote — inclusive proprietários — sem flags extras:

```bash
nix profile add nixpkgs#vscode
nix profile add nixpkgs#google-chrome
nix profile add nixpkgs#slack
nix profile add nixpkgs#obs-studio
```

O app aparece no GNOME imediatamente. O ícone correto aparece após relogar.

Para apps que precisam de aceleração GPU, o nixGL já vem instalado:

```bash
nixGL nome-do-app
```

---

## Atualizações

O GitHub Actions rebuilda a imagem toda semana em cima da versão mais recente do Bluefin. O sistema recebe as atualizações normalmente via `rpm-ostree upgrade`. Os pacotes Nix instalados persistem entre atualizações porque ficam em `/var/home/nix`, que não é sobrescrito pelo sistema imutável.

---

## Stack completa

| Caso de uso | Ferramenta recomendada |
|---|---|
| CLI tools, dev tools, apps em geral | `nix profile add` |
| Apps GUI que precisam de GPU | Flatpak |
| Ambientes de desenvolvimento isolados | distrobox |
| Scripts e automações | brew |