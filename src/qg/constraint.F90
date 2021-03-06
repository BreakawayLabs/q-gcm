module constraint

  use box, only: box_type
  use modes, only: modes_type
  use intsubs, only: trapin

  implicit none

  private

     ! atmcs, atmcn are vectors containing the quantities (one for each
     ! layer) required for the momemtum constraints at the southern and
     ! northern boundaries respectively, at the current time. atmcsp,
     ! atmcnp are these quantities at the previous time level

     ! ocncs, ocncn are vectors containing the quantities (one for each
     ! layer) required for the momemtum constraints at the southern and
     ! northern boundaries respectively, at the current time (for the
     ! cyclic case). ocncsp, ocncnp are these quantities at the previous
     ! time level

  type constraint_type

     double precision, allocatable :: cs(:), cn(:)
     double precision, allocatable :: csp(:), cnp(:)

     ! ajis, ajin are the integrals of the Jacobian advection terms
     ! in the fluid near the southern and northern boundaries (the
     ! non-cancelling part of the Jacobian integral) for each layer
     double precision, allocatable :: ajis(:),ajin(:)

     ! ap3s, ap3n are the integrals of Ah*d3p/dy3 along the strips
     ! in the fluid near the southern and northern boundaries
     ! for each layer

     ! ap5s, ap5n are the integrals of Ah*d5p/dy5 along the strips
     ! in the fluid near the southern and northern boundaries
     ! for each layer

     double precision, allocatable :: ap3s(:),ap3n(:),ap5s(:),ap5n(:)

     ! bdrins, bdrinn are integrals of boundary drag near zonal boundaries
     double precision :: bdrins, bdrinn

     double precision, allocatable :: int_Be_n(:), int_Be_s(:)

     ! txis, txin are the integrals of the windstress
     ! component taux along the southern and northern boundaries of the
     ! internal q domain (i.e. 1/2 gridlength in from physical boundaries)
     double precision :: txis, txin

  end type constraint_type

     ! dpiat, dpiatp are the current and previous values of the area
     ! integral of the pressure difference across each internal interface.
     ! This quantity (related to the interface displacement eta) occurs
     ! in the mass continuity constraints in the atmosphere

     ! dpioc, dpiocp contain the current and previous area integrals
     ! of the pressure differences across the internal interfaces in
     ! the ocean, used in applying the mass conservation constraints

  type core_constr_type

     double precision, allocatable :: dpi(:), dpip(:)

     ! Monitoring fields
     double precision, allocatable :: emfr(:), ermas(:)

     ! ermasa, emfrat are the absolute and fractional
     ! mass errors at each atmospheric interface
     ! Computed in atinvq

  end type core_constr_type

  public constraint_type
  public core_constr_type

  public init_constraint
  public init_core_constr
  public step_constraints

contains

  type(constraint_type) function init_constraint(b, mod, p, pm)

    type(box_type), intent(in) :: b
    type(modes_type), intent(in) :: mod
    double precision, intent(in) :: p(b%nxp,b%nyp,b%nl)
    double precision, intent(in) :: pm(b%nxp,b%nyp,b%nl)

    double precision :: pins(b%nl),pinn(b%nl),pinsp(b%nl),pinnp(b%nl)
    integer :: k
    double precision apsp,apnp,aps,apn

    allocate(init_constraint%cs(b%nl))
    allocate(init_constraint%cn(b%nl))
    allocate(init_constraint%csp(b%nl))
    allocate(init_constraint%cnp(b%nl))

    allocate(init_constraint%ajis(b%nl))
    allocate(init_constraint%ajin(b%nl))
    allocate(init_constraint%ap3s(b%nl))
    allocate(init_constraint%ap3n(b%nl))
    allocate(init_constraint%ap5s(b%nl))
    allocate(init_constraint%ap5n(b%nl))
    allocate(init_constraint%int_Be_n(b%nl))
    allocate(init_constraint%int_Be_s(b%nl))

    init_constraint%ajis(:) = 0.0d0
    init_constraint%ajin(:) = 0.0d0
    init_constraint%ap3s(:) = 0.0d0
    init_constraint%ap3n(:) = 0.0d0
    init_constraint%ap5s(:) = 0.0d0
    init_constraint%ap5n(:) = 0.0d0
    init_constraint%int_Be_n(:) = 0.0d0
    init_constraint%int_Be_s(:) = 0.0d0

    ! Line integrate p and dp/dy for all
    ! layers along zonal boundaries
    do k = 1, b%nl
       ! Line integrals of p
       pinsp(k) = trapin(pm(:,1,k), b%nxp, b%dx)
       pins(k)  = trapin(p (:,1,k), b%nxp, b%dx)
       pinnp(k) = trapin(pm(:,b%nyp,k), b%nxp, b%dx)
       pinn(k)  = trapin(p (:,b%nyp,k), b%nxp, b%dx)
       ! Line integrals of dp/dy
       init_constraint%csp(k) = trapin((pm(:,2,k)     - pm(:,1,k))/b%dy,       b%nxp, b%dx)
       init_constraint%cnp(k) = trapin((pm(:,b%nyp,k) - pm(:,b%nyp-1,k))/b%dy, b%nxp, b%dx)
       init_constraint%cs(k)  = trapin((p (:,2,k)     - p (:,1,k))/b%dy,       b%nxp, b%dx)
       init_constraint%cn(k)  = trapin((p (:,b%nyp,k) - p (:,b%nyp-1,k))/b%dy, b%nxp, b%dx)
    enddo

    ! Add pressure integral contributions to
    ! get full momentum constraint quantities
    do k=1,b%nl
       apsp = sum(mod%amat(k,:)*pinsp(:))
       apnp = sum(mod%amat(k,:)*pinnp(:))
       aps = sum(mod%amat(k,:)*pins(:))
       apn = sum(mod%amat(k,:)*pinn(:))
       ! Change sign of southern derivative terms
       init_constraint%csp(k) = -init_constraint%csp(k) + 0.5d0*b%dy*b%fnot*b%fnot*apsp
       init_constraint%cnp(k) =  init_constraint%cnp(k) + 0.5d0*b%dy*b%fnot*b%fnot*apnp
       init_constraint%cs(k)  = -init_constraint%cs(k)  + 0.5d0*b%dy*b%fnot*b%fnot*aps
       init_constraint%cn(k)  =  init_constraint%cn(k)  + 0.5d0*b%dy*b%fnot*b%fnot*apn
    enddo

  end function init_constraint

  type(core_constr_type) function init_core_constr(nl)

    integer, intent(in) :: nl

    allocate(init_core_constr%dpi(nl-1))
    allocate(init_core_constr%dpip(nl-1))

    allocate(init_core_constr%emfr(nl-1))
    allocate(init_core_constr%ermas(nl-1))

    init_core_constr%emfr = 0.0d0
    init_core_constr%ermas = 0.0d0

  end function init_core_constr


  pure subroutine step_constraints(b, tau_sign, tdt, constr)

    type(box_type), intent(in) :: b
    integer, intent(in) :: tau_sign
    double precision, intent(in) :: tdt
    type(constraint_type), intent(inout) :: constr

    double precision :: rhss(b%nl), rhsn(b%nl)
    double precision :: csnew(b%nl), cnnew(b%nl)

    ! Accumulate RHSs for the constraint equations for each layer
    rhss(:) = -0.5d0*b%dy*b%fnot*constr%int_Be_s(:)
    rhsn(:) = -0.5d0*b%dy*b%fnot*constr%int_Be_n(:)

    ! Surface layer
    rhss(1) = rhss(1) + tau_sign*(b%fnot/b%h(1))*constr%txis
    rhsn(1) = rhsn(1) - tau_sign*(b%fnot/b%h(1))*constr%txin

    ! Bottom layer
    rhss(b%nl) = rhss(b%nl) + (b%fnot/b%h(b%nl))*constr%bdrins
    rhsn(b%nl) = rhsn(b%nl) - (b%fnot/b%h(b%nl))*constr%bdrinn

    rhss(:) = rhss(:) + constr%ajis(:) - constr%ap3s(:) +  constr%ap5s(:)
    rhsn(:) = rhsn(:) + constr%ajin(:) + constr%ap3n(:) -  constr%ap5n(:)

    ! Update the constraint vectors
    csnew(:) = constr%csp(:) + tdt*rhss(:)
    cnnew(:) = constr%cnp(:) + tdt*rhsn(:)
    constr%csp(:) = constr%cs(:)
    constr%cnp(:) = constr%cn(:)
    constr%cs(:) = csnew(:)
    constr%cn(:) = cnnew(:)

  end subroutine step_constraints

end module constraint
