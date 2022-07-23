# argocd-workflows

## Helper Command
```bash
watchexec -cr "helm -n argo delete workflows; helm -n argo install workflows .; argo submit -n argo --log /Users/bwagner/workspace/github/bradfordwagner/terraform/bradfordwagner.tf.testbed/workflow.yaml -p git_version=feature/cicd "
```

