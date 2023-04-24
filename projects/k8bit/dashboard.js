fetch('/api/v1/pods')
  .then((response) => response.json())
  .then((response) => {
    const pods = podList.items
    const podNames = pods.map(it => it.metadata.name)
    console.log('PODS:', podNames)
    return response.metadata.resourceVersion
  })
  .then((resourceVersion) => {
    fetch(`/api/v1/pods?watch=1&resourceVersion=${resourceVersion}`).then((response) => {
      /* read line and parse it to json */
      const event = JSON.parse(line)
      const pod = event.object
      console.log('PROCESSING EVENT: ', event.type, pod.metadata.name)
    })
  })
