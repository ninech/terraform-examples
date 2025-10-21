# Terraform Kubernetes cluster example

How to create a Kubernetes cluster with Terraform:

* Review and adjust the credentials in [providers.tf](./providers.tf).
* Apply the module.

	```bash
	# configure the namespace which terraform should use
	$ export TF_VAR_namespace=<your cockpit account name>
	# have a look at the plan
	$ terraform plan
	# apply the module
	$ terraform apply
	# after apply is successful, output the kubeconfig into a file
	$ terraform output -raw kubeconfig > kubeconfig.yaml
	# you should be able to access the newly created cluster
	$ KUBECONFIG=kubeconfig.yaml kubectl get ns
	NAME              STATUS   AGE
	default           Active   57s
	kube-system       Active   56s
	kube-public       Active   56s
	kube-node-lease   Active   56s
	# clean up after you are done
	$ terraform destroy
	```
