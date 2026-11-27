# Роли Kubernetes

| Роль | Права роли | Группы пользователей |
|---|---|---|
| ClusterRole pd-cluster-observer | get/list/watch состояния workloads, сервисов, узлов, namespaces, квот, сетевых политик и RBAC. Без Secrets, логов приложений, exec и изменений. | pd-observers — аудиторы и инженеры мониторинга |
| Role pd-domain-configurator | get/list/watch/create/update/patch/delete Services, ResourceQuota, LimitRange, NetworkPolicy, Ingress только своего namespace. Без Secrets, workloads, exec и RBAC. | pd-sales-ops, pd-housing-ops, pd-finance-ops, pd-data-ops — DevOps соответствующих доменов; pd-platform-ops |
| ClusterRole pd-infrastructure-configurator | Чтение и изменение Nodes; чтение/создание/изменение Namespaces. Без удаления узлов/namespaces, Secrets, RBAC и выдачи прав. | pd-platform-ops — эксплуатация общей инфраструктуры |
| Role pd-secret-reader | get/list Secrets только в четырёх бизнес-неймспейсах. Без изменения секретов и назначения ролей. | pd-security — специалист ИБ |

Домены: pd-sales (продажи), pd-housing (ЖКУ и «Умный дом»), pd-finance, pd-data. Группа pd-sales-ops не получает права на другие домены. Настройка инфраструктуры и чтение секретов разделены между разными группами.

Скрипт создаёт четыре учебные личности: pd-auditor, pd-sales-operator, pd-security-officer, pd-platform-engineer. CN сертификата задаёт пользователя, O — группу; права назначаются группам. Сертификаты запрашиваются на сутки. Приватные ключи и отдельные kubeconfig сохраняются вне Git; путь выводит create-users.sh.

## Проверка

После команд из корневого README в той же Bash-сессии:

```bash
kubectl --kubeconfig "$USERS_DIR/pd-auditor.conf" auth can-i list pods --all-namespaces
kubectl --kubeconfig "$USERS_DIR/pd-auditor.conf" auth can-i get secrets -n pd-sales
kubectl --kubeconfig "$USERS_DIR/pd-sales-operator.conf" auth can-i create networkpolicies -n pd-sales
kubectl --kubeconfig "$USERS_DIR/pd-sales-operator.conf" auth can-i create networkpolicies -n pd-housing
kubectl --kubeconfig "$USERS_DIR/pd-security-officer.conf" auth can-i get secrets -n pd-housing
kubectl --kubeconfig "$USERS_DIR/pd-security-officer.conf" auth can-i patch secrets -n pd-housing
kubectl --kubeconfig "$USERS_DIR/pd-platform-engineer.conf" auth can-i patch nodes
kubectl --kubeconfig "$USERS_DIR/pd-platform-engineer.conf" auth can-i create clusterrolebindings
```

Ожидается: yes, no, yes, no, yes, no, yes, no. Ответ no возвращает ненулевой код — это ожидаемый отказ, а не ошибка настройки.
