package com.dotmarketing.job.oldbuilds;

import java.io.File;
import java.util.Calendar;
import java.util.List;

import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;

import com.dotcms.content.elasticsearch.business.ESMappingAPIImpl;
import com.dotmarketing.business.APILocator;
import com.dotmarketing.portlets.contentlet.model.Contentlet;
import com.dotmarketing.util.Logger;
import com.liferay.util.FileUtil;

public class OldBuildCleanUpJob implements Job {

    @Override
    public void execute ( JobExecutionContext context ) throws JobExecutionException {
        try {
            Calendar date40days=Calendar.getInstance();
            date40days.add(Calendar.DAY_OF_MONTH, -40);
            Calendar date60days=Calendar.getInstance();
            date60days.add(Calendar.DAY_OF_MONTH, -60);
            String query = "+structureName:DotcmsNightlyBuilds "+
                    " +DotcmsNightlyBuilds.timestamp:["+ESMappingAPIImpl.datetimeFormat.format(date60days)+
                                                       " TO "+ESMappingAPIImpl.datetimeFormat.format(date40days)+"] "+
                    " +live:true ";
            List<Contentlet> oldList = APILocator.getContentletAPI().search(query, 10, 0, "DotcmsNightlyBuilds.timestamp desc", 
                    APILocator.getUserAPI().getSystemUser(), false);
            String path=APILocator.getFileAPI().getRealAssetsRootPath();
            for(Contentlet cont : oldList) {
                String inode = cont.getInode();
                File assetFolder=new File(path+File.separator+inode.charAt(0)+File.separator+inode.charAt(1)+File.separator+inode);
                if(assetFolder.isDirectory()) {
                    Logger.info(this, "deleting old nightly build files from date "+cont.getDateProperty("timestamp"));
                    FileUtil.deltree(assetFolder);
                }
            }
        }
        catch(Exception ex) {
            Logger.error(this, ex.getMessage(), ex);
        }
    }

}