# Modules

At this time, Waffles has no concept of "modules" or "plug-ins". This is intentional.

All resources are currently being bundled into `/lib`. This is because the resource files are so small, it's not expensive (in terms of disk space or bandwidth transfer) to have one large bundle of resources. This also means that there might be some disagreement on the best way a resource is implemented. We'll see how that goes.

Profiles can be thought of as the closest thing to a "module" as they have a defined structure that includes areas for static files and scripts. Profiles may be interchangeable between your various projects, sites, and environments, but they might not be usable for people outside of your domain of responsibility. This is also intentional.

I want Waffles to help people quickly deploy and configure different types of services, but I also want to ensure they learn how the deployment is done and how the software works. I do not want to create a module ecosystem that is taken for granted instead of actually learning and understanding what is being deployed.
