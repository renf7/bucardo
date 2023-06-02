#!/bin/bash

# Install CGI
cpanm CGI || exit 1

# Install DBD::Pg and output the log if it fails
cpanm DBD::Pg || (echo "DBD::Pg install failed, outputting build.log..."; tail /root/.cpanm/work/*/build.log; exit 1)

# Install Encode::Locale
cpanm Encode::Locale || exit 1

# Install Pod::Parser
cpanm Pod::Parser || exit 1
