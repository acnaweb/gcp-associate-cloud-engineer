# gcloud compute

O componente `compute` concentra os comandos relacionados principalmente ao Compute Engine, networking associado, grupos de instâncias, balanceamento de carga e conectividade híbrida.

## Estrutura

```text
gcloud
└── compute
    └── ENTITY
```

## Mapa mental

```mermaid
mindmap
  root((gcloud compute))

    Virtual Machines
      instances
      machine-types
      reservations
      sole-tenancy

    Storage da VM
      disks
      images
      snapshots

    Escalabilidade
      instance-templates
      instance-groups
        managed
        unmanaged

    Networking
      networks
        subnets
      firewall-rules
      routes
      addresses

    Load Balancing
      health-checks
      backend-services
      forwarding-rules
      url-maps
      target-http-proxies
      target-https-proxies
      ssl-certificates
      network-endpoint-groups

    Hybrid Connectivity
      routers
      vpn-gateways
      vpn-tunnels
      external-vpn-gateways
      interconnects
        attachments

    Localização
      regions
      zones
```

## Exemplos

```bash
gcloud compute instances list
gcloud compute disks list
gcloud compute networks list
gcloud compute networks subnets list
gcloud compute instance-groups managed list
gcloud compute health-checks list
gcloud compute backend-services list
gcloud compute routers list
```

## Observação

Nem todas as entidades aparecem obrigatoriamente no mesmo nível real da CLI.

Exemplo:

```text
gcloud
└── compute
    └── networks
        └── subnets
```

e:

```text
gcloud
└── compute
    └── instance-groups
        └── managed
```
