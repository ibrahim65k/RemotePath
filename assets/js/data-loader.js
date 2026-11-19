(function(){
  const config=window.REMOTEPATH_CONFIG;
  const hosted=location.hostname==='ibrahim65k.github.io';
  const base=hosted?config.basePath:'';
  const allowed=new Set(['categories','specializations','prompt-guidance','platforms','tools','work-models']);
  const pending=new Map();
  window.RemotePathData={
    load(name){
      if(!allowed.has(name))return Promise.reject(new Error('Unknown RemotePath data set: '+name));
      if(pending.has(name))return pending.get(name);
      const request=fetch(base+'data/'+encodeURIComponent(name)+'.json').then(response=>{if(!response.ok)throw new Error('Could not load '+name+' ('+response.status+')');return response.json()}).catch(error=>{pending.delete(name);throw error});
      pending.set(name,request);return request;
    },
    clearCache(){pending.clear();}
  };
})();
