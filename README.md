### Things tested
- [x] Compatibility with AKS current network
- [x] Deploy onboarding sample
- [x] Traffic metrics
- [x] Dashboard
- [x] mTLS
- [ ] Traffic management features
  - [ ] Circuit breaking

### Table comparison between istio and cillium

### Istio
![Istio](https://istio.io/latest/docs/ops/deployment/architecture/arch.svg)

#### Enabling sidecar injection

##### Namespace
All the pods need to be restart in order to have the sidecar injected, istio does that using a mutating webhook that intercepts the pod creation request and injects initContainer (in case of not using Istion CNI plugin) and the sidecar container.
```bash
kubectl label namespace default istio-injection=enabled
```

##### Deployment
The deployment needs to have the sidecar injected, we can do that by adding the annotation `sidecar.istio.io/inject: "true"` to the pod template.

##### InitContainer
The initContainer is responsible for setting up the network namespace and the iptables rules to redirect the traffic to the sidecar container. Example of command that is executed by the initContainer:
```bash
istio-iptables -p "15001" -z "15006" -u "1337" -m REDIRECT -i '*' -x "" -b '*' -d 15090,15021,15020 --log_output_level=default:info
```

The initContainer has the iptables binary and the istio-iptables script that is responsible for setting up the iptables rules. The main problem with that is that the container needs special privileges to be able to change the iptables rules. 
```
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      add:
        - NET_ADMIN
        - NET_RAW
      drop:
        - ALL
    privileged: false
    readOnlyRootFilesystem: false
    runAsGroup: 0
    runAsNonRoot: false
    runAsUser: 0
```

#### Traffic metrics
Istio uses envoy to collect the metrics and send to the telemetry service. The telemetry service is responsible for storing the metrics and expose them to the dashboard.

We can use prometheus to scrap the metrics from istio control plane (istiod) and the envoy proxies (ports ending with -envoy-prom) and grafana/kiali to visualize them. Kiali for example fetch data from prometheus.

#### mTLS
mTLS is for default enabled with istio, but not enforced. We can enforce mTLS by setting the policy to STRICT. It will require all the services to have a valid certificate.
https://istio.io/latest/blog/2023/secure-apps-with-istio/#cryptographic-identity
https://istio.io/latest/blog/2023/secure-apps-with-istio/#enforce-strict-mtls

#### VirtualService and DestinationRule
The VirtualService and DestinationRule are the main resources used to configure the traffic management in istio. The VirtualService is responsible for defining the routing rules and the DestinationRule is responsible for defining the traffic policies.

What if we mess up configuration in a virtual service or DestinationRule ? Istio will ignore the routing and send the traffic to the default route.

In Summary
- VirtualService: Define the routing rules (can accept multiple hosts)
- DestinationRule: Define the traffic policies 

##### ReadinessProbe vs DestinationRule
With trafic policies we will have more control over the traffic, we can define the timeout, retries, circuit breaking, etc. Generatin more reliable services.

#### Ingress

##### Problem with nginx Controller
With the nginx ingress controller it redirects the traffic ignoring the virtual service configuration. The solution would be to use the istio ingress gateway.

So the service upstream close to the ingress will always have this problem when using Istio.

##### Options
###### Kubernetes Ingress API
This method uses the kubernetes ingress API to configure the ingress gateway. The ingress gateway will be responsible for routing the traffic to the services. Very similar to the nginx ingress controller.

###### Classic Istio Ingress Gateway
This method uses the classic istio ingress gateway. The ingress gateway will be responsible for routing the traffic to the services. The ingress gateway will be a service of type LoadBalancer.

###### Kubernetes Gateway API
This method uses the new Kubernetes Gateway API implementation to configure the ingress gateway. The ingress gateway will be responsible for routing the traffic to the services. The ingress gateway will be a service of type LoadBalancer.

#### Kubernetes API Gateway x Istio gateway controller

Kubernetes Gateway API is an entire API specification for dealing with Gateway definition, configuration and management as well as traffic management. We can use this definition for any service mesh that supports it and declared its own gateway class, in summary we can have a gateway to translate the traffic to an internal service in the cluster from a source that doesn't know about the cluster.



##### Supported routing
https://gateway-api.sigs.k8s.io/concepts/api-overview/#route-summary-table

### Q&A
- Is there any additional delay when the services are in the mesh ?

### Links
- https://productpage.staging.telematicsplatform.tools.staging
- https://kiali.staging.telematicsplatform.tools.staging

### References
- https://github.com/carlosgit2016/service-mesh-comparison-poc.git