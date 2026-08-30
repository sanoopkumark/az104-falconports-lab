// FalconPorts Group — AZ-104 lab
// Deploys a minimal, cost-conscious VM + networking stack for one cluster.
// Usage:
//   az deployment group create -g rg-ports-prod --template-file iac/main.bicep \
//     --parameters iac/parameters/falconports.parameters.json

@description('Cluster this deployment belongs to (Ports, Maritime, Logistics, FreeZones, Platform)')
param clusterName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('VM admin username')
param adminUsername string

@description('SSH public key for the admin user')
@secure()
param adminSshPublicKey string

@description('VM size — keep to burstable B-series for cost')
param vmSize string = 'Standard_B1s'

@description('Address space for this cluster VNet')
param vnetAddressPrefix string = '10.1.0.0/16'

@description('Address space for the workload subnet')
param subnetAddressPrefix string = '10.1.1.0/24'

var namePrefix = toLower(clusterName)
var tags = {
  Cluster: clusterName
  Environment: 'Lab'
  Project: 'AZ104-FalconPorts'
}

module network 'modules/network.bicep' = {
  name: '${namePrefix}-network'
  params: {
    location: location
    vnetName: 'vnet-${namePrefix}'
    vnetAddressPrefix: vnetAddressPrefix
    subnetName: 'snet-${namePrefix}-web'
    subnetAddressPrefix: subnetAddressPrefix
    tags: tags
  }
}

module compute 'modules/compute.bicep' = {
  name: '${namePrefix}-compute'
  params: {
    location: location
    vmName: 'vm-${namePrefix}-web-001'
    vmSize: vmSize
    adminUsername: adminUsername
    adminSshPublicKey: adminSshPublicKey
    subnetId: network.outputs.subnetId
    nsgId: network.outputs.nsgId
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  name: '${namePrefix}-storage'
  params: {
    location: location
    storageAccountName: 'st${namePrefix}${uniqueString(resourceGroup().id)}'
    tags: tags
  }
}

output vmName string = compute.outputs.vmName
output storageAccountName string = storage.outputs.storageAccountName
output vnetName string = network.outputs.vnetName
