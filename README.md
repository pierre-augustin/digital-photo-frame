# Cadre photo numérique DIY

Diaporama plein écran automatique sur Raspberry Pi 4, combinant photos
stockées en local et sur un NAS, sans authentification requise.

## Statut : ✅ Fonctionnel

## Matériel
- Raspberry Pi 4 2GB
- MicroSD 128GB
- Câble micro-HDMI vers HDMI
- Écran 20" HDMI (non tactile)
- Alimentation officielle Pi 4 (5V/3A) — **essentiel**, voir
  docs/troubleshooting.md

## OS
Raspberry Pi OS (Bookworm+, session graphique Wayland/labwc)
Utilisateur : `pat`

## Sources de photos
1. **Local** : `/home/pat/images`
2. **NAS Synology DS220+** : monté via NFS (pas de SMB/credentials)
   - Export : `/volume1/photo`
   - Point de montage : `/mnt/nas-photos`
   - Accès autorisé côté Synology par IP (pas d'authentification requise)

## Fonctionnement
- **feh** affiche les deux dossiers en boucle, ordre aléatoire,
  recherche récursive dans les sous-dossiers
- Démarre automatiquement au boot via un service **systemd** dédié
  (PAS via `~/.config/autostart`, qui ne fonctionne pas sous
  Wayland/labwc sur ce système)
- Autologin en session graphique activé (`raspi-config` → System
  Options → Boot / Auto Login → Desktop Autologin)
- Une tâche cron envoie un signal `SIGUSR1` à `feh` toutes les heures
  pour recharger la liste de photos sans interrompre le diaporama —
  les nouvelles photos déposées sur le NAS ou en local apparaissent
  automatiquement
- **Veille nocturne de l'écran** : l'écran s'éteint automatiquement
  pendant une plage horaire configurable (23h–7h par défaut) et se
  rallume ensuite, voir [Veille nocturne](#veille-nocturne-de-lécran)

## Installation

```bash
sudo apt update
sudo apt install -y feh unclutter nfs-common

sudo mkdir -p /mnt/nas-photos
mkdir -p /home/pat/images

# Copier le contenu de config/fstab-entry.txt à la fin de /etc/fstab
# (adapter l'IP du NAS)
sudo nano /etc/fstab

sudo mount -a

# Copier scripts/start-slideshow.sh vers /home/pat/
cp scripts/start-slideshow.sh /home/pat/
chmod +x /home/pat/start-slideshow.sh

# Copier systemd/slideshow.service vers /etc/systemd/system/
sudo cp systemd/slideshow.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable slideshow.service
sudo systemctl start slideshow.service

# Ajouter le contenu de config/crontab-entry.txt
sudo crontab -e

sudo raspi-config
# → System Options → Boot / Auto Login → Desktop Autologin
sudo reboot
```

## Veille nocturne de l'écran

Le script `scripts/screen-sleep.sh` éteint/rallume l'écran HDMI via
`wlopm` (Wayland/labwc — `xset dpms` ne fonctionne pas sous Wayland).
Il est piloté par deux tâches cron qui appellent le script avec `off`
ou `on` aux heures configurées.

### Installation

```bash
sudo apt install -y wlopm

cp scripts/screen-sleep.sh /home/pat/
chmod +x /home/pat/screen-sleep.sh

# Ajouter le contenu de config/crontab-entry.txt (contient déjà les
# lignes de veille en plus du rechargement NAS horaire)
sudo crontab -e
```

### Ajuster les heures de veille

Éditer les deux lignes cron dans `config/crontab-entry.txt` (ou
directement via `crontab -e`) :

```cron
0 23 * * * /home/pat/screen-sleep.sh off
0 7  * * * /home/pat/screen-sleep.sh on
```

Le premier champ/deuxième champ est `minute heure` — remplacer `23` et
`7` par les heures souhaitées (0-23). Pas besoin de redémarrer le
service slideshow : `feh` continue de tourner en arrière-plan pendant
la veille, seul l'écran physique s'éteint, et le diaporama réapparaît
immédiatement au réveil de l'écran.

### Test manuel

```bash
DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 /home/pat/screen-sleep.sh off
DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 /home/pat/screen-sleep.sh on
```

## Paramètres ajustables

| Paramètre | Fichier | Détail |
|---|---|---|
| Durée d'affichage par photo | `scripts/start-slideshow.sh` | option `--slideshow-delay` (secondes), redémarrer le service après modif |
| Fréquence de rafraîchissement NAS | `config/crontab-entry.txt` | ajuster la syntaxe cron |
| Ordre d'affichage | déjà aléatoire | option `--randomize` |
| Dossiers sources | `scripts/start-slideshow.sh` | arguments finaux de la commande feh |
| Heures de veille écran | `config/crontab-entry.txt` | deux lignes cron `screen-sleep.sh off`/`on`, voir [Veille nocturne](#veille-nocturne-de-lécran) |

## Accès distant

**SSH** : `ssh pat@<IP_DU_PI>`

**Bureau distant graphique** : non résolu avec XRDP (conflit avec la
session Wayland/labwc locale — voir docs/troubleshooting.md).
RealVNC Server natif recommandé mais non testé en remplacement.
