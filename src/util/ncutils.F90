module ncutils

  implicit none
  include 'netcdf.inc'

  private

  public handle_err
  public nc_close
  public nc_create
  public nc_open
  public nc_open_w

  public nc_def_dim
  public nc_get_dim

  public nc_def_float

  public nc_def_int
  public nc_get_int

  public nc_def_double
  public nc_get_double

  public nc_get_text

  public nc_enddef

  interface nc_get_int
     module procedure nc_get_int
     module procedure nc_get_int_1d
  end interface nc_get_int

  interface nc_get_double
     module procedure nc_get_double
     module procedure nc_get_double_1d
     module procedure nc_get_double_2d
     module procedure nc_get_double_3d
  end interface nc_get_double

  interface nc_def_double
     module procedure nc_def_double
     module procedure nc_def_double_nd
  end interface nc_def_double

  interface nc_def_float
     module procedure nc_def_float
     module procedure nc_def_float_nd
  end interface nc_def_float

  public nc_put_int

  interface nc_put_int
     module procedure nc_put_int
     module procedure nc_put_int_id
     module procedure nc_put_int_simple
  end interface

  public nc_put_double

  interface nc_put_double
     module procedure nc_put_double_block_1d_id
     module procedure nc_put_double_block_2d_id
     module procedure nc_put_double_block_3d_id
     module procedure nc_put_double_block_1d_name
     module procedure nc_put_double_block_2d_name
     module procedure nc_put_double_block_3d_name
     module procedure nc_put_double_line_array_1d_id
     module procedure nc_put_double_line_array_1d_name
     module procedure nc_put_double_line_array_2d_id
     module procedure nc_put_double_line_array_2d_name
     module procedure nc_put_double_line_array_3d_id
     module procedure nc_put_double_line_array_3d_name
     module procedure nc_put_double_line_scalar_id
     module procedure nc_put_double_line_scalar_name
  end interface nc_put_double

contains

  subroutine handle_err (ncstat, fromst, msg)

    integer, intent(in) ::  ncstat
    character (len=*), intent(in), optional :: fromst
    character (len=*), intent(in), optional :: msg

    ! fromst is an optional string indicating where the call came
    ! from that caused the netCDF problem (e.g. subroutine name)

    ! Routine which interprets errors from netCDF output functions,
    ! prints them to standard output and then kills the whole run.
    if ( ncstat.ne.NF_NOERR ) then
       if ( present(fromst) .and. present(msg) ) then
          print *, trim(fromst)//': '//trim( nf_strerror(ncstat))//': '//msg
       else if ( present(fromst) ) then
          print *, trim(fromst)//': '//trim( nf_strerror(ncstat) )
       else
          print *, trim( nf_strerror(ncstat) )
       endif
       stop 1
    endif

  end subroutine handle_err

  subroutine nc_close(ncid, subnam)

    integer, intent(in) :: ncid
    character (len=*), intent(in), optional :: subnam

    integer :: status

    status = nf_close(ncid)
    if (status.ne.NF_NOERR) call handle_err (status, subnam)

  end subroutine nc_close

  integer function nc_create(outdir, filename, subnam)
    
    character (len=*), intent(in) :: outdir
    character (len=*), intent(in) :: filename
    character (len=*), intent(in), optional :: subnam

    integer :: status

    status = nf_create (trim(outdir)//'/'//filename, NF_CLOBBER, nc_create)
    if ( status.ne.NF_NOERR ) call handle_err (status, subnam, trim(outdir)//'/'//filename)

  end function nc_create

  integer function nc_open(filename, subnam)

    character (len=*), intent(in) :: filename
    character (len=*), intent(in), optional :: subnam

    integer :: status

    status = nf_open(filename,NF_NOWRITE,nc_open)
    if ( status.ne.NF_NOERR ) call handle_err (status, subnam, filename)

  end function nc_open

  integer function nc_open_w(outdir, filename, subnam)

    character (len=*), intent(in) :: outdir
    character (len=*), intent(in) :: filename
    character (len=*), intent(in), optional :: subnam

    integer :: status

    status = nf_open(trim(outdir)//'/'//filename,NF_WRITE,nc_open_w)
    if ( status.ne.NF_NOERR ) call handle_err (status, subnam, filename)

  end function nc_open_w

  double precision function nc_get_double(ncid, varname, subnam)

    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat, varid

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_get_var_double(ncid, varid, nc_get_double)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)

  end function nc_get_double

  function nc_get_double_1d(ncid, varname, n, subnam)

    integer, intent(in) :: n
    double precision :: nc_get_double_1d(n)
    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat, varid

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_get_var_double(ncid, varid, nc_get_double_1d)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)

  end function nc_get_double_1d

  function nc_get_double_2d(ncid, varname, n, m, subnam)

    integer, intent(in) :: n,m
    double precision :: nc_get_double_2d(n,m)
    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat, varid

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_get_var_double(ncid, varid, nc_get_double_2d)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)

  end function nc_get_double_2d

  function nc_get_double_3d(ncid, varname, n, m, zzzz, subnam)

    integer, intent(in) :: n,m, zzzz
    double precision :: nc_get_double_3d(n,m,zzzz)
    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat, varid

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_get_var_double(ncid, varid, nc_get_double_3d)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)

  end function nc_get_double_3d

  integer function nc_def_dim(ncid, dimname, n, subnam)
    
    integer, intent(in) :: ncid
    character (len=*), intent(in) :: dimname
    integer, intent(in) :: n
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat

    ncstat = nf_def_dim(ncid, dimname, n, nc_def_dim)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end function nc_def_dim

  integer function nc_get_dim(ncid, dimname, subnam)

    integer, intent(in) :: ncid
    character (len=*), intent(in) :: dimname
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat, varid

    ncstat = nf_inq_dimid(ncid, dimname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    ncstat = nf_inq_dimlen(ncid, varid, nc_get_dim)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end function nc_get_dim

  subroutine nc_enddef(ncid, subnam)

    integer, intent(in) :: ncid
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat

    ncstat = nf_enddef(ncid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    
  end subroutine nc_enddef

  integer function nc_def_float(ncid, varname, dim, units, subnam, longname)

    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    integer, intent(in) :: dim
    character (len=*), intent(in) :: units
    character (len=*), intent(in), optional :: subnam
    character (len=*), intent(in), optional :: longname

    integer :: ncstat

    ncstat = nf_def_var(ncid, varname, NF_FLOAT, 1, dim, nc_def_float)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    ncstat = nf_put_att_text(ncid ,nc_def_float,'units',len(units),units)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    if (present(longname)) then
       ncstat = nf_put_att_text(ncid ,nc_def_float,'long_name',len(longname),longname)
       if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    endif

  end function nc_def_float

  integer function nc_def_float_nd(ncid, varname, dims, units, subnam, longname)
    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    integer, intent(in) :: dims(:)
    character (len=*), intent(in) :: units
    character (len=*), intent(in), optional :: subnam
    character (len=*), intent(in), optional :: longname

    integer :: ncstat 

    ncstat = nf_def_var(ncid, varname, NF_FLOAT, size(dims), dims, nc_def_float_nd)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    ncstat = nf_put_att_text(ncid, nc_def_float_nd, 'units', len(units), units)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    if (present(longname)) then
       ncstat = nf_put_att_text(ncid, nc_def_float_nd, 'long_name', len(longname), longname)
       if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    endif

  end function nc_def_float_nd

  integer function nc_def_int(ncid, varname, dims, units, subnam, longname)
    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    integer, intent(in) :: dims(:)
    character (len=*), intent(in) :: units
    character (len=*), intent(in), optional :: subnam
    character (len=*), intent(in), optional :: longname

    integer :: ncstat 

    ncstat = nf_def_var(ncid, varname, NF_INT, size(dims), dims, nc_def_int)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    ncstat = nf_put_att_text(ncid, nc_def_int, 'units', len(units), units)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    if (present(longname)) then
       ncstat = nf_put_att_text(ncid, nc_def_int, 'long_name', len(longname), longname)
       if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    endif

  end function nc_def_int

  integer function nc_def_double(ncid, varname, dim, units, subnam, longname)

    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    integer, intent(in) :: dim
    character (len=*), intent(in) :: units
    character (len=*), intent(in), optional :: subnam
    character (len=*), intent(in), optional :: longname

    integer :: ncstat

    ncstat = nf_def_var(ncid, varname, NF_DOUBLE, 1, dim, nc_def_double)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    ncstat = nf_put_att_text(ncid ,nc_def_double,'units',len(units),units)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    if (present(longname)) then
       ncstat = nf_put_att_text(ncid ,nc_def_double,'long_name',len(longname),longname)
       if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    endif

  end function nc_def_double

  integer function nc_def_double_nd(ncid, varname, dims, units, subnam, longname)

    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    integer, intent(in) :: dims(:)
    character (len=*), intent(in) :: units
    character (len=*), intent(in), optional :: subnam
    character (len=*), intent(in), optional :: longname

    integer :: ncstat

    ncstat = nf_def_var(ncid, varname, NF_DOUBLE, size(dims), dims, nc_def_double_nd)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    ncstat = nf_put_att_text(ncid, nc_def_double_nd,'units',len(units),units)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    if (present(longname)) then
       ncstat = nf_put_att_text(ncid,nc_def_double_nd,'long_name',len(longname),longname)
       if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)
    endif

  end function nc_def_double_nd

  integer function nc_get_int(ncid, varname, subnam)

    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat, varid

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_get_var_int(ncid, varid, nc_get_int)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)

  end function nc_get_int

  function nc_get_int_1d(ncid, varname, n, subnam)

    integer, intent(in) :: n
    integer :: nc_get_int_1d(n)
    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat, varid

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_get_var_int(ncid, varid, nc_get_int_1d)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)

  end function nc_get_int_1d

  subroutine nc_get_text(ncid, varname, data, subnam)

    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    character, allocatable, intent(inout) :: data(:)
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat, varid

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_get_var_text(ncid, varid, data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)

  end subroutine nc_get_text

  subroutine nc_put_int(nc_id, varname, start, count, data, subnam)
    integer, intent(in) :: nc_id
    character (len=*), intent(in) :: varname
    integer, intent(in) :: start(:)
    integer, intent(in) :: count(:)
    integer, intent(in) :: data(:)
    character (len=*), intent(in) :: subnam

    integer :: ncstat, varid

    ncstat = nf_inq_varid(nc_id, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_put_vara_int(nc_id, varid, start, count, data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_int

  subroutine nc_put_int_id(nc_id, varid, start, count, data, subnam)
    integer, intent(in) :: nc_id
    integer, intent(in) :: varid
    integer, intent(in) :: start(:)
    integer, intent(in) :: count(:)
    integer, intent(in) :: data(:)
    character (len=*), intent(in) :: subnam

    integer :: ncstat

    ncstat = nf_put_vara_int(nc_id, varid, start, count, data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_int_id

  subroutine nc_put_int_simple(nc_id, varid, data, subnam)
    integer, intent(in) :: nc_id
    integer, intent(in) :: varid
    integer, intent(in) :: data(:)
    character (len=*), intent(in) :: subnam

    integer :: ncstat

    ncstat = nf_put_var_int(nc_id, varid, data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_int_simple


  subroutine nc_put_double_block_1d_id(ncid, varid, data, subnam)

    integer, intent(in) :: ncid
    integer, intent(in) :: varid
    double precision, intent(in) :: data(:)
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat

    ncstat = nf_put_vara_double(ncid, varid, 1, size(data), data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_block_1d_id

  subroutine nc_put_double_block_2d_id(ncid, varid, data, subnam)

    integer, intent(in) :: ncid
    integer, intent(in) :: varid
    double precision, intent(in) :: data(:,:)
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat

    ncstat = nf_put_vara_double(ncid, varid, (/1, 1/), shape(data), data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_block_2d_id

  subroutine nc_put_double_block_3d_id(ncid, varid, data, subnam)

    integer, intent(in) :: ncid
    integer, intent(in) :: varid
    double precision, intent(in) :: data(:,:,:)
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat

    ncstat = nf_put_vara_double(ncid, varid, (/1, 1, 1/), shape(data), data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_block_3d_id

  subroutine nc_put_double_block_1d_name(ncid, varname, data, subnam)

    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    double precision, intent(in) :: data(:)
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat, varid

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_put_vara_double(ncid, varid, 1, size(data), data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_block_1d_name

  subroutine nc_put_double_block_2d_name(ncid, varname, data, subnam)

    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    double precision, intent(in) :: data(:,:)
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat, varid

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_put_vara_double(ncid, varid, (/1, 1/), shape(data), data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_block_2d_name

  subroutine nc_put_double_block_3d_name(ncid, varname, data, subnam)

    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    double precision, intent(in) :: data(:,:,:)
    character (len=*), intent(in), optional :: subnam

    integer :: ncstat, varid

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_put_vara_double(ncid, varid, (/1, 1, 1/), shape(data), data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_block_3d_name

! nc_put_double_line_scalar_id (ncid, varid, start, data, subname) (nc_put_float are a bit like this...)
! nc_put_double_line_array_id 
! nc_put_double_line_scalar_name (ncid, varname, start, data, subname)
! nc_put_double_line_array_name

  subroutine nc_put_double_line_array_1d_name(ncid, varname, start, data, subnam)
    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    integer, intent(in) :: start
    double precision, intent(in) :: data(:)
    character (len=*), intent(in) :: subnam

    integer :: ncstat, varid
    integer :: startt(2), count(2)

    startt = (/1, start/)
    count = (/size(data), 1/)

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_put_vara_double(ncid, varid, startt, count, data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_line_array_1d_name

  subroutine nc_put_double_line_array_1d_id(ncid, varid, start, data, subnam)
    integer, intent(in) :: ncid
    integer, intent(in) :: varid
    integer, intent(in) :: start
    double precision, intent(in) :: data(:)
    character (len=*), intent(in) :: subnam

    integer :: ncstat
    integer :: startt(2), count(2)

    startt = (/1, start/)
    count = (/size(data), 1/)

    ncstat = nf_put_vara_double(ncid, varid, startt, count, data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_line_array_1d_id

  subroutine nc_put_double_line_array_2d_name(ncid, varname, start, data, subnam)
    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    integer, intent(in) :: start
    double precision, intent(in) :: data(:,:)
    character (len=*), intent(in) :: subnam

    integer :: ncstat, varid
    integer :: startt(3), count(3)

    startt = (/1, 1, start/)
    count = (/shape(data), 1/)

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_put_vara_double(ncid, varid, startt, count, data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_line_array_2d_name

  subroutine nc_put_double_line_array_2d_id(ncid, varid, start, data, subnam)
    integer, intent(in) :: ncid
    integer, intent(in) :: varid
    integer, intent(in) :: start
    double precision, intent(in) :: data(:,:)
    character (len=*), intent(in) :: subnam

    integer :: ncstat
    integer :: startt(3), count(3)

    startt = (/1, 1, start/)
    count = (/shape(data), 1/)

    ncstat = nf_put_vara_double(ncid, varid, startt, count, data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_line_array_2d_id

  subroutine nc_put_double_line_array_3d_name(ncid, varname, start, data, subnam)
    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    integer, intent(in) :: start
    double precision, intent(in) :: data(:,:,:)
    character (len=*), intent(in) :: subnam

    integer :: ncstat, varid
    integer :: startt(4), count(4)

    startt = (/1, 1, 1, start/)
    count = (/shape(data), 1/)

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_put_vara_double(ncid, varid, startt, count, data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_line_array_3d_name

  subroutine nc_put_double_line_array_3d_id(ncid, varid, start, data, subnam)
    integer, intent(in) :: ncid
    integer, intent(in) :: varid
    integer, intent(in) :: start
    double precision, intent(in) :: data(:,:,:)
    character (len=*), intent(in) :: subnam

    integer :: ncstat
    integer :: startt(4), count(4)

    startt = (/1, 1, 1, start/)
    count = (/shape(data), 1/)

    ncstat = nf_put_vara_double(ncid, varid, startt, count, data)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_line_array_3d_id

  subroutine nc_put_double_line_scalar_name(ncid, varname, start, data, subnam)
    integer, intent(in) :: ncid
    character (len=*), intent(in) :: varname
    integer, intent(in) :: start
    double precision, intent(in) :: data
    character (len=*), intent(in) :: subnam

    integer :: ncstat, varid
    integer :: startt(2), count(2)

    startt = (/start, 1/)
    count = (/1, 1/)

    ncstat = nf_inq_varid(ncid, varname, varid)
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam, varname)
    ncstat = nf_put_vara_double(ncid, varid, startt, count, (/data/))
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_line_scalar_name

  subroutine nc_put_double_line_scalar_id(ncid, varid, start, data, subnam)
    integer, intent(in) :: ncid
    integer, intent(in) :: varid
    integer, intent(in) :: start
    double precision, intent(in) :: data
    character (len=*), intent(in) :: subnam

    integer :: ncstat
    integer :: startt(2), count(2)

    startt = (/1, start/)
    count = (/1, 1/)

    ncstat = nf_put_vara_double(ncid, varid, startt, count, (/data/))
    if ( ncstat.ne.NF_NOERR ) call handle_err (ncstat, subnam)

  end subroutine nc_put_double_line_scalar_id
  
end module ncutils
