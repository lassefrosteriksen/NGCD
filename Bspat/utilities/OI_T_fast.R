#+
`OI_T_fast`<-function(yo.sel,
                      yb.sel,
                      xb.sel,
                      xgrid.sel,
                      ygrid.sel,
                      zgrid.sel,
                      lgrid.sel,
                      VecX.sel,
                      VecY.sel,
                      VecZ.sel,
                      VecLaf.sel,
                      Dh.cur,
                      Dz.cur,
                      lafmin) {
#------------------------------------------------------------------------------
  no<-length(yo.sel)
  ng<-length(xb.sel)
  xa.sel<-vector(mode="numeric",length=ng)
  xidi.sel<-vector(mode="numeric",length=ng)
  vec<-vector(mode="numeric",length=no)
  vec1<-vector(mode="numeric",length=no)
  xa.sel[]<-0
  xidi.sel[]<-0
  d<-yo.sel-yb.sel
  out<-.C("oi_t_first",no=as.integer(no), 
                       innov=as.double(d),
                       SRinv=as.numeric(InvD),
                       vec=as.double(vec), vec1=as.double(vec1) )
  vec[1:no]<-out$vec[1:no]
  vec1[1:no]<-out$vec1[1:no]
  rm(out)
  out<-.C("oi_t_fast",ng=as.integer(ng),
                      no=as.integer(no),
                      xg=as.double(xgrid.sel),
                      yg=as.double(ygrid.sel),
                      zg=as.double(zgrid.sel),
                      lg=as.double(lgrid.sel),
                      xo=as.double(VecX.sel),
                      yo=as.double(VecY.sel),
                      zo=as.double(VecZ.sel),
                      lo=as.double(VecLaf.sel),
                      Dh=as.double(Dh.cur),
                      Dz=as.double(Dz.cur),
                      lafmin=as.double(lafmin),
                      xb=as.double(xb.sel),
                      vec=as.double(vec),
                      vec1=as.double(vec1),
                      xa=as.double(xa.sel),
                      xidi=as.double(xidi.sel) )
  xa.sel[1:ng]<-out$xa[1:ng]
  xidi.sel[1:ng]<-out$xidi[1:ng]
  rm(out)
  return(list(xa=xa.sel,xidi=xidi.sel))
}
