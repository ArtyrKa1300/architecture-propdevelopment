# PropDevelopment — спринт 5

| Задание | Решение |
|---|---|
| 1. Классификация и риски | [Mindmap](Task1/data-security.drawio) |
| 2. Бизнес-системы | [Проверочный лист](Task2/security-checklist.md) |
| 3. Внешние интеграции | [Контекст](Task3/context.drawio), [контейнеры](Task3/containers.drawio), [требования](Task3/requirements.md) |
| 4. RBAC | [Роли и проверки](Task4/roles.md), три скрипта в Task4 |
| 5. Сетевые политики | [NetworkPolicy](Task5/non-admin-api-allow.yaml) |

## Task4: запуск

Нужны Docker, Minikube, kubectl, OpenSSL и Bash. Из корня репозитория:

```bash
minikube start -p propdevelopment --driver=docker --cni=calico --keep-context
USERS_DIR=$(bash Task4/create-users.sh)
bash Task4/create-roles.sh
bash Task4/bind-users.sh
```

Calico обеспечивает применение NetworkPolicy. Проверки разрешений и ожидаемые ответы — в [Task4/roles.md](Task4/roles.md).

## Task5: запуск и проверка

```bash
kubectl --context propdevelopment create namespace pd-network
for role in front-end back-end-api admin-front-end admin-back-end-api; do
  kubectl --context propdevelopment -n pd-network run "$role-app" --image=nginx:1.28-alpine --labels="role=$role" --expose --port=80
done
kubectl --context propdevelopment -n pd-network wait --for=condition=Ready pod --all --timeout=180s
kubectl --context propdevelopment apply -f Task5/non-admin-api-allow.yaml
kubectl --context propdevelopment -n pd-network exec front-end-app -- wget -qO- -T 2 http://back-end-api-app
kubectl --context propdevelopment -n pd-network exec front-end-app -- wget -qO- -T 2 http://admin-back-end-api-app
```

Первый запрос возвращает страницу Nginx, второй завершается по тайм-ауту. Аналогично проверяются обратные направления и пара admin-front-end ↔ admin-back-end-api. Разрешены только пары на TCP/80 и DNS к CoreDNS; остальные соединения, включая новые поды без разрешённой роли, запрещены.

Остановка: `minikube stop -p propdevelopment`.
