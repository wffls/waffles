# Modules

At this time, Waffles has no concept of "modules" or "plug-ins". This is intentional.

All resources are currently being bundled into `/lib`. This is because the resource files are so light-weight, there's no external cost of just having one large bundle of resources. This also means that there might be some disagreement on the best way a resource is implemented. We'll see how that goes.

Profiles can be thought of as the closest thing to a "module" as they have a defined structure that includes areas for static files and scripts. Profiles might be interchangable between various projects, sites, and environments of yours, but they might not be usable for people outside of your domain of responsibility. This is also intentional. I want Waffles to help people quickly deploy and configure different types of services, but I also want to ensure they learn how the deployment is done and how the software works. I do not want to create a module ecosystem is taken for granted and used instead of actually learning what is being deployed.
