# Funktionalität

Im OTRS Standard ist es nicht möglich ConfigItems einer bestimmten Klasse als dynamisches Feld zu hinterlegen.

Mit diesem Paket kann man Konfiguration für dynamische Felder anlegen, um dynamischen Felder vom Typ Mehrfachauswahl mit den Werten einer CI-Klassen zu erstellen.

Es handelt sich hierbei um ein einfaches Dropdown oder eine Mehrfachauswahl. Bitte beachten Sie, dass diese Felder nur für kleine ConfigItem-Listen (<2000 Elemente pro Klasse) ausgelegt sind.

Sobald ein dynamisches Feld dieses Typs angelegt wird, kann der Admin auswählen, welche CMDB-Klasse für dieses Feld hinterlegt werden soll.

Das dynamische Feld zeigt dann in den Eingabemasken den Namen der ConfigItems der Klasse an.
