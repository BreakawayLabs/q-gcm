module ml_monitor

  use box, only: box_type
  use ncutils, only: nc_open_w, nc_create, nc_def_dim, nc_def_float, nc_close, nc_put_double, nc_enddef
  use grid, only: grid_type, new_load_grid
  use intsubs, only: genint
  use box, only: box_type
  use qg, only: qg_type
  use grid, only: grid_type
  use ekman, only: ekman_type
  use amlsubs, only: atmos_mixed_type
  use omlsubs, only: ocean_mixed_type

  implicit none

  private

  type oml_monitor_type

     logical :: active = .false.
     integer :: nocmon
     character (len=64) :: filename

     double precision :: hfmloc

     ! hfmloc is the heat flux at the bottom of the ocean m.l. (W m^-2)
     ! = Integ (oTm'*Wekman) dA / Area
     ! Computed in diagno

     double precision :: wetm, watm
     ! wepmoc, wepmat are mean Ekman velocities at p points (should be zero)
     ! wapmoc, wapmat are mean modulus of Ekman velocities at p points
     ! wetmoc, wetmat are mean Ekman velocities at T points (should be zero)
     ! watmoc, watmat are mean modulus of Ekman velocities at T points
     ! All the above are in (m s^-1).
     ! Computed in diagno

     ! Mean mixed layer value
     double precision :: mean_st

  end type oml_monitor_type

  type aml_monitor_type

     logical :: active = .false.
     integer :: nocmon
     type(grid_type) :: g
     character (len=64) :: filename

     double precision :: tmaooc
     ! tmaooc is the mean atmos. m.l. (rel) temp over the ocean

     double precision :: slhfav,oradav,arocav,arlaav
     ! slhfav, oradav are heat fluxes averaged over ocean (W m^-2)
     ! arocav, arlaav are atmospheric radiative fluxes (upwards +ve)
     ! averaged over ocean and land respectively (W m^-2)
     ! All computed in xforc, so no duplication.

     double precision :: hcmlat
     ! hcmlat is the total heat content of the atmos. m.l. (J m^-2)
     ! = Integ (aTm'*ahm) dA / Area
     ! Computed in diagno


     double precision :: olrtop
     ! olrtop is the mean outgoing longwave radiation
     ! perturbation at the top of the atmosphere (W m^-2)
     ! Computed in diagno

     double precision :: wetm, watm
     ! wepmoc, wepmat are mean Ekman velocities at p points (should be zero)
     ! wapmoc, wapmat are mean modulus of Ekman velocities at p points
     ! wetmoc, wetmat are mean Ekman velocities at T points (should be zero)
     ! watmoc, watmat are mean modulus of Ekman velocities at T points
     ! All the above are in (m s^-1).
     ! Computed in diagno

     ! Mean mixed layer value
     double precision :: mean_st
     double precision :: mean_h

  end type aml_monitor_type

  public oml_monitor_type
  public aml_monitor_type

  public init_oml_monitor
  public init_aml_monitor

  public oml_monitor_step
  public aml_monitor_step

  public update_aml_monitor
  public update_oml_monitor

contains

  type(oml_monitor_type) function init_oml_monitor(nocmon, filename, outdir, numoutsteps)

    integer, intent(in) :: nocmon
    character (len=*), intent(in) :: filename
    character (len=*), intent(in) :: outdir
    integer, intent(in) :: numoutsteps

    init_oml_monitor%nocmon = nocmon
    init_oml_monitor%filename = filename
    init_oml_monitor%active = .true.

    call oml_monnc_init(outdir, numoutsteps, filename)

  end function init_oml_monitor

  type(aml_monitor_type) function init_aml_monitor(nocmon, filename, go, ga, outdir, numoutsteps)

    integer, intent(in) :: nocmon
    character (len=*), intent(in) :: filename
    type(box_type), intent(in) :: go, ga
    character (len=*), intent(in) :: outdir
    integer, intent(in) :: numoutsteps

    init_aml_monitor%nocmon = nocmon
    init_aml_monitor%filename = filename
    init_aml_monitor%g = new_load_grid(go, ga)
    init_aml_monitor%active = .true.

    call aml_monnc_init(outdir, numoutsteps, filename)

  end function init_aml_monitor
  
  logical function oml_monitor_step(ntdone, oml_mon, force)
    integer, intent(in) :: ntdone
    type(oml_monitor_type), intent(in) :: oml_mon
    logical, intent(in) :: force

    oml_monitor_step = oml_mon%active .and. (force .or. mod(ntdone,oml_mon%nocmon).eq.0 )

  end function oml_monitor_step

  logical function aml_monitor_step(ntdone, aml_mon, force)
    integer, intent(in) :: ntdone
    type(aml_monitor_type), intent(in) :: aml_mon
    logical, intent(in) :: force

    aml_monitor_step = aml_mon%active .and. (force .or. mod(ntdone,aml_mon%nocmon).eq.0 )

  end function aml_monitor_step

  subroutine update_aml_monitor(qga, aml_mon, eka, aml, qg_mon_etam, outdir, ntdone, tyrs)

    type(qg_type), intent(in) :: qga
    type(aml_monitor_type), intent(inout) :: aml_mon
    type(ekman_type), intent(in) :: eka
    type(atmos_mixed_type), intent(in) :: aml
    double precision, intent(in) :: qg_mon_etam(qga%b%nl-1)
    character (len=*), intent(in) :: outdir
    integer, intent(in) :: ntdone
    double precision, intent(in) :: tyrs

    call diagnose_aml(qga%b, qga, aml_mon%g, eka, aml, qg_mon_etam, aml_mon)
    call aml_monnc_out(outdir, ntdone, aml_mon%nocmon, tyrs, aml_mon)

  end subroutine update_aml_monitor

  subroutine update_oml_monitor(oml, eko, oml_mon, outdir, ntdone, tyrs)
    type(ocean_mixed_type), intent(in) :: oml
    type(ekman_type), intent(in) :: eko
    type(oml_monitor_type), intent(inout) :: oml_mon
    character (len=*), intent(in) :: outdir
    integer, intent(in) :: ntdone
    double precision, intent(in) :: tyrs

    call diagnose_oml(oml, oml%b, eko, oml_mon)
    call oml_monnc_out(outdir, ntdone, oml_mon%nocmon, tyrs, oml_mon)

  end subroutine update_oml_monitor

  subroutine diagnose_aml(ga, qga, g, eka, aml, qga_mon_etam, aml_mon)

    ! Computes as many as possible of the diagnostic quantities
    ! required for monitoring/debugging the QG climate model.
    ! A few quantities (e.g. convection) need to be computed
    ! as part of the actual timestepping; otherwise try to do
    ! all calculations in this routine for efficiency.
    ! The routine should be called after xforc; at this point
    ! in the timestepping all quantities are consistent.
    ! The results are all written to monitor.cmn

    ! N.B. use included integration routine genint for all area
    ! integrations, rather than earlier routine xintt, to enable
    ! efficient parallelisation using "orphaned directives",
    ! within a parallel context defined in this subroutine.

    type(box_type), intent(in) :: ga
    type(qg_type), intent(in) :: qga
    type(grid_type), intent(in) :: g
    type(ekman_type), intent(in) :: eka
    type(atmos_mixed_type), intent(in) :: aml
    double precision, intent(in) :: qga_mon_etam(ga%nl-1)
    type(aml_monitor_type), intent(inout) :: aml_mon
      
    integer :: i,j

    ! Define atmosphere variables
    double precision attwk1(ga%nxt,ga%nyt)

    ! Atmosphere diagnostics
    ! Mixed layer temperature & thickness diagnostics

    aml_mon%slhfav = aml%slhfav
    aml_mon%oradav = aml%oradav
    aml_mon%arocav = aml%arocav
    aml_mon%arlaav = aml%arlaav

    ! Compute mean atmos. mixed layer temperature and thickness
    aml_mon%mean_st = genint(aml%ast%data, ga%nxt, ga%nyt, 1.0d0, 1.0d0)
    aml_mon%mean_st = aml_mon%mean_st*ga%norm
       
    aml_mon%mean_h = genint(aml%hmixa%data, ga%nxt, ga%nyt, 1.0d0, 1.0d0)
    aml_mon%mean_h = aml_mon%mean_h*ga%norm

    ! Compute total heat content of atmos m.l.
    attwk1(:,:) = aml%ast%data(:,:)*aml%hmixa%data(:,:)
    aml_mon%hcmlat = genint(attwk1, ga%nxt, ga%nyt, 1.0d0, 1.0d0)
    aml_mon%hcmlat = aml%temp%rho_cp*aml_mon%hcmlat*ga%norm

    ! Compute mean atmos. mixed layer temperature over ocean
    aml_mon%tmaooc = 0.0d0
    do j=g%ny1,g%ny1+g%nyaooc-1
       do i=g%nx1,g%nx1+g%nxaooc-1
          aml_mon%tmaooc = aml_mon%tmaooc + aml%ast%data(i,j)
       enddo
    enddo
    aml_mon%tmaooc = aml_mon%tmaooc/dble( g%nxaooc*g%nyaooc )

    ! Compute mean outoing long wave radiation
    if (qga%active) then
       aml_mon%olrtop = aml%rad%Aup(ga%nl,0)*(aml_mon%mean_h-ga%hm) + &
            aml%rad%Aup(ga%nl,0)*qga%topo%davg + aml%rad%Dup(ga%nl)*aml_mon%mean_st
       do i=1,ga%nl-1
          aml_mon%olrtop = aml_mon%olrtop + aml%rad%Aup(ga%nl,i)*qga_mon_etam(i)
       enddo
    endif

    ! Mean value of Wekman at T points
    aml_mon%wetm = genint(eka%wekt, ga%nxt, ga%nyt, 1.0d0, 1.0d0)
    ! Mean value of abs( Wekman ) at T points
    aml_mon%watm = genint(abs(eka%wekt(:,:)), ga%nxt, ga%nyt, 1.0d0, 1.0d0)
    aml_mon%wetm = aml_mon%wetm*ga%norm
    aml_mon%watm = aml_mon%watm*ga%norm
    
  end subroutine diagnose_aml


  subroutine diagnose_oml(oml, go, eko, oml_mon)
    type(ocean_mixed_type), intent(in) :: oml
    type(box_type), intent(in) :: go
    type(ekman_type), intent(in) :: eko
    type(oml_monitor_type), intent(inout) :: oml_mon

    ! Define ocean variables
    double precision Twekt(go%nxt,go%nyt)

    oml_mon%mean_st = genint(oml%sst%data, go%nxt, go%nyt, 1.0d0, 1.0d0)
    oml_mon%mean_st = oml_mon%mean_st*go%norm

    ! Mixed layer temperature & thickness diagnostics       
    ! Compute flux of heat at bottom of ocean m.l.
    Twekt(:,:) = oml%sst%data(:,:)*eko%wekt(:,:)
    oml_mon%hfmloc = genint(Twekt, go%nxt, go%nyt, 1.0d0, 1.0d0)
    oml_mon%hfmloc = oml%temp%rho_cp*oml_mon%hfmloc*go%norm

    ! Mean value of Wekman at T points
    oml_mon%wetm = genint(eko%wekt, go%nxt, go%nyt, 1.0d0, 1.0d0)
    ! Mean value of abs( Wekman ) at T points
    oml_mon%watm = genint(abs(eko%wekt(:,:)), go%nxt, go%nyt, 1.0d0, 1.0d0)
    oml_mon%wetm = oml_mon%wetm*go%norm
    oml_mon%watm = oml_mon%watm*go%norm

  end subroutine diagnose_oml

  subroutine aml_monnc_init (outdir, numoutsteps, filename)

    character (len=*), intent(in) :: outdir
    integer, intent(in) :: numoutsteps
    character (len=*), intent(in) :: filename

    integer :: tmp_id, monncid

    character :: subnam*(*)
    parameter ( subnam = 'monnc_init' )

    integer :: timedim

    monncid = nc_create(outdir, filename, subnam)

    timedim = nc_def_dim(monncid, 'time', numoutsteps, subnam)
    tmp_id = nc_def_float(monncid, 'time', timedim, 'years', subnam, 'Time')

    ! Atmosphere diagnostics from diagno
    tmp_id = nc_def_float(monncid, 'wetmat', timedim, 'm/s', subnam, 'Average atmospheric Ekman velocity (T-grid)')
    tmp_id = nc_def_float(monncid, 'watmat', timedim, 'm/s', subnam, 'Absolute atmospheric Ekman velocity (T-grid)')
    tmp_id = nc_def_float(monncid, 'tmlmat', timedim, 'K', subnam, 'Average atmospheric mixed layer temperature')
    tmp_id = nc_def_float(monncid, 'hmlmat', timedim, 'm', subnam, 'Average atmospheric mixed layer thickness')
    tmp_id = nc_def_float(monncid, 'hcmlat', timedim, 'K.m^3', subnam, 'Total heat content of atmospheric mixed layer')
    tmp_id = nc_def_float(monncid, 'tmaooc', timedim, 'K', subnam, 'Mean atmospheric mixed layer temperature over ocean')
    tmp_id = nc_def_float(monncid, 'olrtop', timedim, 'W/m^2', subnam, 'Outgoing longwave radiation')

    ! Flux diagnostics from xforc
    tmp_id = nc_def_float(monncid, 'slhfav', timedim, 'W/m^2', subnam, 'Average oceanic sensible and latent heat flux')
    tmp_id = nc_def_float(monncid, 'oradav', timedim, 'W/m^2', subnam, 'Average oceanic radiative heat flux')
    tmp_id = nc_def_float(monncid, 'arocav', timedim, 'W/m^2', subnam, 'Average atmospheric radiative heat flux (over ocean)')
    tmp_id = nc_def_float(monncid, 'arlaav', timedim, 'W/m^2', subnam, 'Average atmospheric radiative heat flux (over land)')
    
    ! Leave definition mode: entering data mode.
    call nc_enddef(monncid, subnam)

    call nc_close(monncid)

  end subroutine aml_monnc_init

  subroutine oml_monnc_init (outdir, numoutsteps, filename)

    character (len=*), intent(in) :: outdir
    integer, intent(in) :: numoutsteps
    character (len=*), intent(in) :: filename

    integer :: tmp_id, monncid

    character :: subnam*(*)
    parameter ( subnam = 'monnc_init' )

    integer :: timedim

    monncid = nc_create(outdir, filename, subnam)

    timedim = nc_def_dim(monncid, 'time', numoutsteps, subnam)
    tmp_id = nc_def_float(monncid, 'time', timedim, 'years', subnam, 'Time')

    ! Ocean diagnostics from diagno
    tmp_id = nc_def_float(monncid, 'wetmoc', timedim, 'm/s', subnam, 'Average oceanic Ekman velocity (T-grid)')
    tmp_id = nc_def_float(monncid, 'watmoc', timedim, 'm/s', subnam, 'Absolute oceanic Ekman velocity (T-grid)')
    tmp_id = nc_def_float(monncid, 'tmlmoc', timedim, 'K', subnam, 'Average oceanic mixed layer temperature')
    tmp_id = nc_def_float(monncid, 'hfmloc', timedim, 'W/m^2', subnam, 'Heat flux at bottom of ocean mixed layer')

    ! Leave definition mode: entering data mode.
    call nc_enddef(monncid, subnam)

    call nc_close(monncid)
    
  end subroutine oml_monnc_init

  subroutine aml_monnc_out (outdir, nt, nocmon, tyrs, aml_mon)

    character (len=*), intent(in) :: outdir
    integer, intent(in) :: nt, nocmon
    double precision, intent(in) :: tyrs
    type(aml_monitor_type), intent(in) :: aml_mon

    integer :: monncid

    character :: subnam*(*)
    parameter ( subnam = 'monnc_out' )

    ! Netcdf variables used locally
    integer :: startt

    monncid = nc_open_w(outdir, aml_mon%filename, subnam)

    ! Store current time as part of 'time' vector
    startt = nt/nocmon+1
    call nc_put_double(monncid, 'time', startt, tyrs, subnam)

    call nc_put_double(monncid, 'tmlmat', startt, aml_mon%mean_st, subnam)
    call nc_put_double(monncid, 'hmlmat', startt, aml_mon%mean_h, subnam)

    call nc_put_double(monncid, 'wetmat', startt, aml_mon%wetm, subnam)
    call nc_put_double(monncid, 'watmat', startt, aml_mon%watm, subnam)

    call nc_put_double(monncid, 'hcmlat', startt, aml_mon%hcmlat, subnam)
    call nc_put_double(monncid, 'tmaooc', startt, aml_mon%tmaooc, subnam)
    call nc_put_double(monncid, 'olrtop', startt, aml_mon%olrtop, subnam)

    ! Store flux diagnostics from xforc
    call nc_put_double(monncid, 'slhfav', startt, aml_mon%slhfav, subnam)
    call nc_put_double(monncid, 'oradav', startt, aml_mon%oradav, subnam)
    call nc_put_double(monncid, 'arocav', startt, aml_mon%arocav, subnam)
    call nc_put_double(monncid, 'arlaav', startt, aml_mon%arlaav, subnam)

    call nc_close(monncid)

  end subroutine aml_monnc_out

  subroutine oml_monnc_out (outdir, nt, nocmon, tyrs, oml_mon)

    character (len=*), intent(in) :: outdir
    integer, intent(in) :: nt, nocmon
    double precision, intent(in) :: tyrs
    type(oml_monitor_type), intent(in) :: oml_mon

    integer :: monncid

    character :: subnam*(*)
    parameter ( subnam = 'monnc_out' )

    ! Netcdf variables used locally
    integer :: startt

    monncid = nc_open_w(outdir, oml_mon%filename, subnam)

    ! Store current time as part of 'time' vector
    startt = nt/nocmon+1
    call nc_put_double(monncid, 'time', startt, tyrs, subnam)

    call nc_put_double(monncid, 'wetmoc', startt, oml_mon%wetm, subnam)
    call nc_put_double(monncid, 'watmoc', startt, oml_mon%watm, subnam)

    ! Store ocean diagnostics from oml
    call nc_put_double(monncid, 'tmlmoc', startt, oml_mon%mean_st, subnam)

    ! Actually atmos m.l. variable
    call nc_put_double(monncid, 'hfmloc', startt, oml_mon%hfmloc, subnam)

    call nc_close(monncid)

  end subroutine oml_monnc_out

end module ml_monitor
