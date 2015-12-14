docker-compose run --rm fhirbase bash ./build.sh && cat tmp/build.sql | docker-compose run --rm db psql -U postgres -h db -d postgres
