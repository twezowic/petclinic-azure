Na początku tworzymy maszyny za pomocą skryptu: ```./deploy.sh config.json```. Skrypt oprócz tworzenia maszyn uzupełnia plik inventory.yaml oraz folder /vars.

Następnie sprawdza czy ansible może nawiązać połączenie z maszynami za pomocą komendy: ```ansible -i inventory.yaml all -m ping```
![image.png](photos/lab2_3.png)



Aby uruchomić poszególne konfiguracje należy mieć zainstalowany ansible, a następnie wywołać komendę:
``` ansible-playbook playbookN.yaml -i inventory.yaml```
,gdzie N to numer konfiguracji

## 1
``` ansible-playbook playbook1.yaml -i inventory.yaml```
![image.png](photos/lab2_6.png)
![image.png](photos/lab2_7.png)
![image.png](photos/lab2_8.png)

Po zakończeniu skryptu można przejść do stron frontendu oraz backendu. Adresy ip znajdują się w pliku inventory.yaml

Adres frontendu: {front_ip}:8080
![image.png](photos/lab2_1.png)
Adres backendu: {back_ip}:8080/petclinic
![image.png](photos/lab2_9.png)

## 2
``` ansible-playbook playbook1.yaml -i inventory.yaml```
W 2 konfiguracji właczamy wykonywanie skryptu dla backendu w pętli na maszynie backend_VM.
![image.png](photos/lab2_5.png)

Uzyskujemy połącznie przez nginx.


![image.png](photos/lab2_2.png)

## 5
``` ansible-playbook playbook5.yaml -i inventory.yaml```