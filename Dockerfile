# Use postgres:15.3 image as base
FROM postgres:15.3

# Environment variables for Postgres
ENV POSTGRES_USER postgres
ENV POSTGRES_PASSWORD postgres
ENV POSTGRES_DB postgres

# Update and Install needed software
RUN apt-get update \
    && apt-get install -y perl make postgresql-plperl-15 libdbix-safe-perl libboolean-perl libjson-perl git cpanminus libpq-dev build-essential jq curl net-tools netcat iputils-ping vim

# Copy the installation script
COPY install_modules.sh /tmp/install_modules.sh

# Run the installation script
RUN /tmp/install_modules.sh

# Clone bucardo repo
RUN git clone https://github.com/bucardo/bucardo.git

# Change owner of the bucardo directory to postgres
RUN chown -R postgres:postgres /bucardo

WORKDIR /bucardo

RUN mkdir -p /var/log/bucardo /var/run/bucardo && chown -R postgres:postgres /var/log/bucardo /var/run/bucardo

# Build and install Bucardo
RUN perl Makefile.PL \
    && make \
    && make install \
    && chown -R postgres:postgres /usr/local/bin/bucardo /var/log/bucardo /var/run/bucardo

# Create /media directory if it doesn't exist
RUN mkdir -p /media && chown -R postgres:postgres /media

# Expose Postgres port
EXPOSE 5432

RUN mkdir -p /opt/bucardo
COPY check_json.sh /opt/bucardo/

# Switch to the postgres user
USER postgres

# create file owned by postgres to allow execution 'bucardo restart sync' as postgres user
RUN touch bucardo.restart.reason.txt

# Copy the entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint-initdb.d/

# Switch back to root user
USER root

# Add metadata to an image
LABEL maintainer="rafalszymonduda@outlook.com"

# Start PostgreSQL
CMD ["postgres"]