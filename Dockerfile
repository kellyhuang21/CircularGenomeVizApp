FROM kbase/sdkbase2:python
MAINTAINER Kelly Huang <kellyhuang@berkeley.edu>
# -----------------------------------------
# In this section, you can install any system dependencies required
# to run your App.  For instance, you could place an apt-get update or
# install line here, a git checkout to download code, or run any other
# installation scripts.

# RUN apt-get update

RUN \
    wget http://wishart.biology.ualberta.ca/cgview/application/cgview.zip \
    && unzip cgview.zip \
    && rm cgview.zip

# -----------------------------------------

COPY ./ /kb/module
RUN mkdir -p /kb/module/work
RUN chmod -R a+rw /kb/module

WORKDIR /kb/module

RUN make all

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD [ ]
