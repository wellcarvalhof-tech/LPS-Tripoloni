/* Service worker do LPS Tripoloni.
 *
 * Objetivo: o app abrir na obra mesmo sem sinal. Guarda o shell (o index.html e as bibliotecas
 * de CDN) e serve do cache quando a rede falha. Dado de obra NÃO passa por aqui — o que vem do
 * Supabase é sempre rede, e o que fica offline é o retrato guardado pelo próprio app no IndexedDB.
 *
 * Pra publicar uma versão nova: suba o VERSAO. O app avisa na tela e recarrega quando o usuário
 * mandar.
 */
var VERSAO='lps-v14';
var SHELL=['./','./index.html','./manifest.webmanifest','./icons/icon-192.png','./icons/icon-512.png'];

self.addEventListener('install',function(e){
  e.waitUntil(caches.open(VERSAO).then(function(c){
    // addAll falha inteiro se um item falhar; aqui cada um vai por conta própria.
    return Promise.all(SHELL.map(function(u){ return c.add(u).catch(function(){}); }));
  }));
});

self.addEventListener('activate',function(e){
  e.waitUntil(caches.keys().then(function(ks){
    return Promise.all(ks.map(function(k){ return k===VERSAO?null:caches.delete(k); }));
  }).then(function(){ return self.clients.claim(); }));
});

self.addEventListener('message',function(e){ if(e.data==='pular-espera')self.skipWaiting(); });

self.addEventListener('fetch',function(e){
  var req=e.request;
  if(req.method!=='GET')return;
  var url;
  try{ url=new URL(req.url); }catch(err){ return; }
  if(url.protocol!=='http:'&&url.protocol!=='https:')return;
  // Supabase (dados e login) nunca entra em cache: resposta velha aqui seria pior que erro.
  if(/supabase\.(co|in)$/.test(url.hostname))return;

  // Navegação: tenta a rede (pra pegar versão nova) e cai pro shell guardado se não houver sinal.
  if(req.mode==='navigate'){
    e.respondWith(fetch(req).then(function(r){
      var copia=r.clone(); caches.open(VERSAO).then(function(c){ c.put('./index.html',copia); });
      return r;
    }).catch(function(){
      return caches.match('./index.html').then(function(r){ return r||caches.match('./'); });
    }));
    return;
  }

  // Resto (nosso estático + bibliotecas de CDN + fontes): cache primeiro, rede depois.
  e.respondWith(caches.match(req).then(function(cached){
    if(cached)return cached;
    return fetch(req).then(function(r){
      if(r&&(r.status===200||r.type==='opaque')){
        var copia=r.clone(); caches.open(VERSAO).then(function(c){ c.put(req,copia); });
      }
      return r;
    });
  }));
});
