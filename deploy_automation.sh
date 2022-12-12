#!/bin/sh

#Build images for Production(v1) and Canary (v2)
helm del reference-app -n reference-service-showcase
eval $(minikube -p minikube docker-env)
# make docker-build-minikube-stable
# sed -i -e 's/V1/V2/g'  ./service/src/main/java/io/cecg/referenceapplication/api/controllers/GreetingController.java
# make docker-build-minikube-canary
# sed -i -e 's/V2/V1/g'  ./service/src/main/java/io/cecg/referenceapplication/api/controllers/GreetingController.java
# minikube image ls | grep ref-service



# make deploy-manifests
# osascript -e 'tell app "Terminal" to do script "kubectl port-forward svc/ingress-nginx-controller -n ingress-nginx 8474:80"'
# make enable-proxy
echo "##################################"
echo "                                 #"
echo "Creating a Canary deployment..   #"
echo "                                 #"
echo "##################################"
helm install service/k8s-manifests/helm-charts --name-template reference-app --create-namespace -n reference-service-showcase --wait > /dev/null

if [ $? -eq 0 ]; then
   echo OK
else
   helm del reference-app -n reference-service-showcase
   echo FAIL
   exit 1
fi

sleep 5
echo ""
echo "#########################################"
echo "                                        #"
echo "Simulate traffic to Reference Ingress   #"
echo "                                        #"
echo "#########################################"
echo ""
osascript -e 'tell app "Terminal" to do script "kubectl port-forward svc/ingress-nginx-controller -n ingress-nginx 8474:80"'
sleep 60
osascript -e 'tell app "Terminal" to do script "for i in {1..1000};  do curl  localhost:8474/service/hello ; echo \"\" ; sleep 1; done"'
echo ""
echo "####################################"
echo "                                  #"
echo "Smoke test on Canary deployment   #"
echo "                                  #"
echo "###################################"
echo ""

for i in {1..10}
do
      curl -s localhost:8474/service/hello -H "X-Canary: always"

      if [ $? -ne 0 ]; then
         helm del reference-app -n reference-service-showcase
         echo "Smoke Test : FAILED" 
         exit 1
      fi
      echo ""
      sleep 2
done

echo ""
echo "###################################################"
echo "                                                  #"
echo "Reset total request metric of canary deployment   #"
echo "                                                  #"
echo "###################################################"
echo ""

kubectl rollout restart deploy/canary-reference-app -n reference-service-showcase
if [ $? -ne 0 ]; then
     helm del reference-app -n reference-service-showcase
      echo "Restart Canary deployment : FAILED" 
      exit 1
fi
sleep 30
echo ""
echo "######################################################"
echo "                                                     #"
echo "Reroute  50% of traffic to Canary deployment        #"
echo "                                                     #"
echo "######################################################"
echo ""
helm upgrade reference-app  service/k8s-manifests/helm-charts  -n reference-service-showcase --reuse-values --set canary.weight=50 --wait > /dev/null
sleep 90
# for i in {1..30}
# do
# echo ""
# sleep 1
# curl -s localhost:8474/service/hello
# done


curl -s http://localhost:9093/api/v2/alerts\?active | jq '.[].labels | select (.alertname == "CanaryPodNoTraffic")' | wc -l 
echo ""
echo "######################################################################"
echo "                                                                     #"
echo "Checking alert of TotalRequest of Canary deployment in Alertmanager  #"
echo "                                                                     #"
echo "######################################################################"
echo ""

if [[ $(curl -s http://localhost:9093/api/v2/alerts\?active | jq '.[].labels | select (.alertname == "CanaryPodNoTraffic")' | wc -l ) -ne 0 ]]; then
    echo "No traffic to Canary deployment"
    helm upgrade reference-app  service/k8s-manifests/helm-charts  -n reference-service-showcase --reuse-values --set canary.weight=100 --wait > /dev/null
   
else
echo ""
echo "######################################################"
echo "                                                     #"
echo "Reroute  100% of traffic to Canary deployment        #"
echo "                                                     #"
echo "######################################################"
echo ""
helm upgrade reference-app  service/k8s-manifests/helm-charts  -n reference-service-showcase --reuse-values --set canary.weight=100 --wait > /dev/null
sleep 30
echo ""
echo "###################################################"
echo "                                                  #"
echo "Update image tag of production deployment to v2   #"
echo "                                                  #"
echo "###################################################"
echo ""
    helm upgrade reference-app  service/k8s-manifests/helm-charts  -n reference-service-showcase  --reuse-values --set image.tag=v2 --wait > /dev/null
    sleep 30
echo ""
echo "######################################################"
echo "                                                     #"
echo "Reroute  100% of traffic to Production deployment    #"
echo "                                                     #"
echo "######################################################"
echo ""
    helm upgrade reference-app  service/k8s-manifests/helm-charts  -n reference-service-showcase --reuse-values --set canary.weight=0 --wait > /dev/null
    sleep 10
# for i in {1..60}
# do
# echo ""
# sleep 1
# curl -s localhost:8474/service/hello
# done

fi


# helm del reference-app -n reference-service-showcase