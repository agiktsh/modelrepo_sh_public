# modelrepo_sh_public

## Anwendungsdokumentation

Usecase#1: Ein publiziertes Modell ändern

### 1. Repository lokal klonen / letzte Aktualisierungen nach lokal pullen (mit Visual Studio Code)




### 2. Branch eröffnen und publizieren für das Änderungsvorhaben

1. Branch > Create new branch: Anschliessend Namen für das Vorhaben eingeben (zB. "Modellanpassungen-092026-LA-LandwirtschaftlicheEignung")
2. Anschliessend den Branch publizieren (damit ist er auf GitHub und nicht nur lokal sichtbar)
3. Sicherstellen, dass in Visual Studio Code der neue Branch gesetzt ist 

### 3. Änderung durchführen

In der lokalen Modelldatei die Änderung einpflegen.

### 4. Änderung auf den Branch committen

Änderung committen und pushen

Nun läuft eine GitHub Action ab, welche
1. ilimodels.xml aufgrund der Änderung aktualisiert
2. Das Repository auf Validität prüft
3. ilimodels.xml auf dem aktuellen Branch aktualisiert

### 5. Pullrequest erstellen

Beim Erstellen des PullRequests laufen zwei Checks ab, welche beide bestanden werden müssen (Dauer: ca. 100s). Solange die Tests nicht bestanden sind, ist das Merging auf main blockiert.

### 6. Pullrequest in Hauptentwicklungsast mergen und Branch löschen



### 7. Repository publizieren

anschliessend kann das öffentliche Rpository mit dem Stand des main-Branches (komplett) aktualisiert werden.
Dazu kann das ZIP-File aus Releases verwendet werden: https://github.com/agiktsh/modelrepo_sh_public/releases
