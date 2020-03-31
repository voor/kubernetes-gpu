# Kubernetes Cluster API GPU Support

Adding a GPU enabled node to a Kubernetes Cluster created with Cluster API.

## Try it out

Create a Cluster in US-East-1 and then add the additional VMs located in `kubernetes-gpu/additional-vms.yaml`.  Make sure to change `clusterName` as necessary in the MachineDeployment.

On the management cluster:
```
kubectl apply -f additional-vms.yaml
```

Afterwards you need to activate the GPU enabled runtime by applying `runtimeclass.yaml`

On the GPU enabled cluster:
```
kubectl apply -f runtimeclass.yaml
```

Turn on the NVIDIA Device Plugin, which has been modified to use the NVIDIA containerd runtime class.
```
kubectl apply -f nvidia-device-plugin.yaml
```

Finally, run a GPU enabled example that is requesting 1 GPU and using the containerd runtime class.
```
kubectl apply -f notebook-example.yml
kubectl port-forward tf-notebook 8888:8888
```

## Building the Image

1. Checkout [Image Builder](https://github.com/kubernetes-sigs/image-builder) to another repository that is relative to this repository. 
    ```
    $ ls -1 | grep 'kubernetes-gpu\|image-builder'   
    kubernetes-gpu
    image-builder
    ```
1. Next, modify `nvidia-containerd.json` to provide the absolute path to the `kubernetes-gpu` repository for the `extra_repos` option.  In the example, it's located in my `$HOME` directory under `workspace`.
1. Create a `.secrets/secrets.json` file that contains the missing credentials options from Image Builder.  Since we pass this file in last it'll override everything else in packer, here's an example:
    ```
    {
    "aws_region": "us-east-1",
    "aws_profile": "com",
    "ami_regions": "us-east-1",
    "vpc_id": "vpc-123456",
    "subnet_id": "subnet-123456",
    "ssh_keypair_name": "cluster-api-provider-aws",
    "iam_instance_profile": "nodes.cluster-api-provider-aws.sigs.k8s.io"
    }
    ```
1. Image Builder by default uses the regular Amazon Linux 2 base AMI, but we want to use one that has NVIDIA drivers pre-installed, so make the following change in `image-builder/images/capi/packer/ami/packer.json`:
    ```
    @@ -135,11 +135,11 @@
        "instance_type": "t3.small",
        "source_ami": "{{user `amazon_2_ami`}}",
        "source_ami_filter": {
            "filters": {
            "virtualization-type": "hvm",
    -          "name": "amzn2-ami-hvm-2*",
    +          "name": "amzn2-ami-graphics-hvm-2*",
            "root-device-type": "ebs",
            "architecture": "x86_64"
            },
            "owners": ["amazon"],
            "most_recent": true
    ```
1. Afterwards, run `build.sh` and get the output of the AMI image, for example: `ami-0728541f6e02e632d`, you would then provide this as the AMI ID in your Machine Deployment.

## What is this customizing?

1. Image Builder is using a base Amazon Linux 2 image with NVIDIA drivers already installed.
1. Adding a containerd runtime class to the containerd configuration.
1. Install the `libnvidia-container` and `nvidia-container-runtime` repositories, then install all RPMs which are dependencies to `nvidia-container-runtime`
1. Using an AWS instance type with a GPU attached instead of a regular instance type.
1. Adding a [Runtime Class](https://kubernetes.io/docs/concepts/containers/runtime-class/) to support mixed workloads (ones that use a GPU and ones that don't)
1. Using the [NVIDIA Device Plugin](https://github.com/NVIDIA/k8s-device-plugin) to handle requesting and limits for GPUs in workloads.
1. Providing the alternative runtime environment for workloads, so that you can keep GPU enabled separate from non-GPU enabled (this follows a similar concept to kata containers).