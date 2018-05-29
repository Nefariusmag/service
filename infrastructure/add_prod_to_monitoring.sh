HOST_PROD=$1
echo "HOST_PROD=${HOST_PROD}" >> .env
sed -i "s|HOST_PROD|${HOST_PROD}|g" monitoring/prometheus/prometheus.yml
docker-compose -f docker-compose-monitoring.yml up -d
