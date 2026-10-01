# modelrepo_sh_public

Dieses Repository ist der Quellstand für das öffentliche INTERLIS-Modell-Repository des Kantons Schaffhausen ([models.geo.sh.ch](https://models.geo.sh.ch/)). Änderungen an Modellen (`*.ili`) oder Katalogen/Daten (`*.xml`) werden hier über Pull Requests eingebracht, automatisiert geprüft und bei jedem Merge nach `main` als GitHub Release veröffentlicht.

## Ordnerstruktur

```
repository/              1:1-Spiegel von https://models.geo.sh.ch/
├── ilimodels.xml        Index aller Modelle (von ilimanager gepflegt)
├── ilidata.xml          Index der Kataloge/Daten (von ilivalidator ergänzt)
├── ilisite.xml          Standort-Metadaten (Name, Titel, Kontakt – manuell gepflegt)
├── AGI/                 Amt für Geoinformation (u.a. amtliche Vermessung, OeREB)
├── FA/                  Forst (Waldfunktionsplanung, Waldreservate)
├── IKL/                 Interkantonales Labor (Versickerungsbereiche, Risikokarte, Abfallanlagen)
├── JF/                  Jagd und Fischerei (Jagdreviere)
├── LA/                  Landwirtschaft (Melioration, landwirtschaftliche Eignung)
├── PNA/                 Planungs- und Naturschutzamt (Nutzungsplanung, Richtplan, Naturschutz)
├── TSH/                 Tiefbau (Strassenrichtplan, Naturgefahrenkarte, Gewässer)
└── _modelldokumentationen/   PDF-Dokumentationen, Struktur spiegelt obige Ordner

.github/
├── workflows/           GitHub Actions (siehe unten)
└── scripts/              Von den Workflows aufgerufene Shell-Scripts
```

Jeder Themenordner kann einen Unterordner `replaced/` enthalten – dort liegen abgelöste, aber aus Kompatibilitätsgründen weiter referenzierbare Modellversionen.

**Wichtig:** `repository/` ist ein byte-exakter Spiegel der publizierten Dateien. Die in `ilimodels.xml`/`ilidata.xml` hinterlegten md5-Prüfsummen beziehen sich auf die Original-Bytes – siehe `.gitattributes` weiter unten.

## GitHub Actions

| Workflow | Trigger | Zweck |
|---|---|---|
| **validate-models.yml** | Push/PR auf `main` | Zwei Required-Status-Checks: `ili2c --check-repo-ilis` (kompiliert alle Modelle aus `ilimodels.xml`) und `ilimanager index freshness` (regeneriert `ilimodels.xml` und `ilidata.xml` zum Abgleich, prüft `ilidata.xml` auf tote Pfade) |
| **update-model-index.yml** | Push auf Arbeits-Branches (nicht `main`), bei geänderten `*.ili`/`*.xml` | Aktualisiert `ilimodels.xml` automatisch (via ilimanager) und validiert den gesamten Stand mit ili2c, bevor der Branch grün wird |
| **validate-new-data.yml** | PR gegen `main`, bei neuen `*.xml`-Dateien | Validiert neue Kataloge/Daten mit `ilivalidator` gegen ihr Modell und ergänzt bei Erfolg automatisch `ilidata.xml` |
| **release.yml** | Push auf `main` | Re-validiert den finalen Stand mit allen drei Tools, baut `repository/` als ZIP (`models.geo.sh.ch_YYYYMMDDHHmm.ZIP`) und veröffentlicht ZIP + Tool-Logs + Datei-Changelog als GitHub Release |

Alle Tool-Versionen (ili2c, ilimanager, ilivalidator) sind in den jeweiligen Workflows als `env:`-Variablen gepinnt und werden bei Bedarf von downloads.interlis.ch heruntergeladen und gecacht.

### Scripts (`.github/scripts/`)

| Script | Verwendet von | Zweck |
|---|---|---|
| `check-ilimodels-index.sh` | validate-models.yml | Prüft, ob `ilimodels.xml` dem aktuellen Dateistand entspricht (ordnungsunabhängiger Vergleich) |
| `check-ilidata-paths.sh` | validate-models.yml | Prüft, ob alle `<path>`-Einträge in `ilidata.xml` auf existierende Dateien zeigen |
| `validate-new-data-files.sh` | validate-new-data.yml, release.yml | Validiert gegebene Dateien mit ilivalidator |
| `add-ilidata-entries.sh` | validate-new-data.yml | Ergänzt `ilidata.xml` um Einträge für neue Dateien |
| `release-validation-logs.sh` | release.yml | Führt ili2c/ilimanager/ilivalidator erneut aus und schreibt ihre Logs nach `/tmp/release-logs/` |
| `generate-changelog.sh` | release.yml | Erstellt die Markdown-Changelog-Sektion der Release-Notes aus dem Datei-Diff zum letzten Release |

## Wichtige Konfigurationen

- **Branch Protection auf `main`:** Pull Request zwingend erforderlich (kein direkter Push), Required Status Checks `ili2c --check-repo-ilis` und `ilimanager index freshness`, keine Umgehung durch Admins.
- **`.gitattributes`:** `repository/** -text` – verhindert, dass Git die Zeilenenden der gespiegelten Dateien verändert (sonst würden die md5-Prüfsummen in `ilimodels.xml`/`ilidata.xml` nicht mehr stimmen, je nach Betriebssystem des Checkouts).
- **Bot-Commits ohne `[skip ci]`:** Die automatischen Commits von `update-model-index.yml` und `validate-new-data.yml` enthalten bewusst **kein** `[skip ci]` – das würde auch `validate-models.yml` für diesen Commit unterdrücken, wodurch ein PR dauerhaft auf „Waiting for status to be reported" hängen bliebe. Ein erneuter Durchlauf auf dem eigenen Bot-Commit ist ungefährlich, da beide Workflows idempotent sind (finden nichts mehr zu tun und beenden sich).
