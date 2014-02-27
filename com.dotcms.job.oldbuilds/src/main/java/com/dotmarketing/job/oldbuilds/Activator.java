package com.dotmarketing.job.oldbuilds;

import java.util.Date;
import java.util.HashMap;

import org.osgi.framework.BundleContext;
import org.quartz.CronTrigger;

import com.dotmarketing.osgi.GenericBundleActivator;
import com.dotmarketing.quartz.CronScheduledTask;

public class Activator extends GenericBundleActivator {

    public final static String JOB_NAME = "Old nightly build clean up";
    public final static String JOB_CLASS = OldBuildCleanUpJob.class.getCanonicalName();
    public final static String JOB_GROUP = "User Jobs";

    public final static String CRON_EXPRESSION = "0 1 * * * ?";

    public void start ( BundleContext context ) throws Exception {

        CronScheduledTask cronScheduledTask =
                new CronScheduledTask( JOB_NAME, JOB_GROUP, JOB_NAME, JOB_CLASS,
                        new Date(), null, CronTrigger.MISFIRE_INSTRUCTION_FIRE_ONCE_NOW,
                        new HashMap<String, Object>(), CRON_EXPRESSION );

        scheduleQuartzJob( cronScheduledTask );
    }

    public void stop ( BundleContext context ) throws Exception {
        //Unregister all the bundle services
        unregisterServices( context );
    }

}