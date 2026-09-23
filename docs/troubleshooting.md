# Problèmes rencontrés et solutions

## 1. Erreur de montage NFS "unknown filesystem type"
Causes possibles :
- Faute de frappe dans l'IP du NAS
- Ligne fstab mal formée (espace/tabulation manquante, ligne résiduelle
  d'un test manuel collée par erreur)
- Paquet `nfs-common` non installé (`sudo apt install -y nfs-common`)

Vérifier le format exact attendu avec :
```bash
showmount -e <IP_DU_NAS>
```
Le chemin doit être copié exactement tel qu'affiché, sans espace ni
guillemet.

## 2. Le diaporama ne démarre pas au boot (autostart XDG silencieux)
`~/.config/autostart/*.desktop` ne fonctionne pas sous labwc (Wayland)
sur Raspberry Pi OS récent — contrairement à l'ancien LXDE.
**Solution** : utiliser un service systemd dédié (voir
`systemd/slideshow.service`) plutôt que le mécanisme autostart XDG.

Vérifier l'environnement de session avant de choisir la méthode :
```bash
echo $XDG_SESSION_TYPE     # wayland
echo $XDG_CURRENT_DESKTOP  # labwc:wlroots
```

## 3. Pi injoignable en SSH/ping après configuration réseau
**Cause racine identifiée** : alimentation insuffisante (voltage/ampérage).
Le Pi 4 nécessite une alimentation stable 5V/3A minimum. En dessous, le
WiFi/réseau devient instable ou tombe complètement, même si l'écran et
l'interface locale semblent fonctionner normalement.

Diagnostic :
```bash
vcgencmd get_throttled
```
- `0x0` = pas de souci d'alimentation
- Tout autre code = undervoltage détecté (actuel ou passé)

**Toujours utiliser l'alimentation officielle Pi 4 (5V/3A)**.

## 4. Bureau distant (RDP) impossible via XRDP
Tentatives infructueuses avec XRDP sur ce système :
- **Session Xorg** : le window manager (labwc) plante systématiquement
  avec SIGSEGV lors du démarrage d'une seconde session sur le même GPU
  — conflit avec la session Wayland locale déjà active
- **Session Xvnc** : deux blocages successifs
  - Incompatibilité de paramètres : XRDP envoie `-rfbauth`, non reconnu
    par la version TigerVNC installée
  - Profondeur de couleur : XRDP demandait `-depth 32`, or Xvnc
    n'accepte que 1-24 (corrigé dans `/etc/xrdp/xrdp.ini` :
    `max_bpp=24` + `xserverbpp=24` décommenté dans la section `[Xvnc]`)
    — corrige le message d'erreur mais la session échoue quand même à
    s'établir

**Piste non testée** : RealVNC Server natif (`realvnc-vnc-server` +
activation via `raspi-config` → Interface Options → VNC). Partage
l'écran physique existant au lieu de créer une session graphique
isolée — approche généralement plus fiable avec Wayland/labwc.

## 5. `xset dpms` ne coupe pas l'écran pour la veille nocturne
`start-slideshow.sh` désactive volontairement le DPMS X11
(`xset -dpms`, `xset s off`) pour empêcher toute mise en veille
intempestive pendant le diaporama — mais ça signifie que `xset dpms
force off` ne fonctionne pas non plus pour une extinction programmée,
et de toute façon `xset` est un outil X11 qui n'a pas d'effet fiable
sous une session Wayland/labwc.

**Solution** : `wlopm` (wlr-output-power-management), qui parle
directement au protocole Wayland du compositeur wlroots (labwc en fait
partie) pour éteindre/rallumer la sortie vidéo, indépendamment de
DPMS/X11. Voir `scripts/screen-sleep.sh` et la section « Veille
nocturne de l'écran » du README.

Si `wlopm --off '*'` ne fait rien :
```bash
# Lister les sorties connues du compositeur et leur état
wlopm
```
Si la commande échoue avec une erreur de connexion au socket Wayland,
vérifier que `XDG_RUNTIME_DIR` et `WAYLAND_DISPLAY` correspondent bien
à la session active (`loginctl show-session` ou `echo
$XDG_RUNTIME_DIR` dans la session graphique elle-même).
