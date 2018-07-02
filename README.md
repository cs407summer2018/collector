# collector

This worker will run periodically as a background job functioning to provide up-to-date CS lab usage information in a manner similar to the [CoRec](https://www.purdue.edu/drsfacilityusage/).

Every regular interval of time x, it will interrogate each lab machine on the network to determine and store any active user sessions.

This data, collected as part of our CS407 Senior Software Engineering Project, will be aggregated on our web application.
