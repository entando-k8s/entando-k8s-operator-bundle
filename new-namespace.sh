kind: Namespace
apiVersion: v1
metadata:
  name: ampie
  annotations:
    scheduler.alpha.kubernetes.io/defaultTolerations: >-
      [{"operator": "Exists", "effect": "NoSchedule", "key": "node-role.kubernetes.io/master"}]