module comp_a
use MCTWrapper
use timeM
use proc_def
    implicit none
    integer  :: comp_id
    !---------------------------------------------------------
    ! notice that the fields of a2x and x2a maybe different
    ! but here we just assume they are same
    !---------------------------------------------------------
    character(len=20) :: fld_ar="x:y"
    character(len=20) :: fld_ai="u:v:w"
    public :: a_init_mct
    public :: a_run_mct
    public :: a_final_mct

contains

!-------------------------------------------------------------------------
!  a_init_mct, init gsmap_aa, avect, avect init with zero, but not init
!  dom at present
!-------------------------------------------------------------------------
subroutine a_init_mct(my_proc, ID, EClock, gsMap_aa, a2x_aa, x2a_aa, ierr)

    implicit none
    type(proc), intent(inout)        :: my_proc
    integer, intent(in)              :: ID
    type(Clock), intent(in)          :: EClock
    type(gsMap), intent(inout)       :: gsMap_aa
    type(AttrVect), intent(inout)    :: a2x_aa
    type(AttrVect), intent(inout)    :: x2a_aa
    integer,  intent(inout)          :: ierr
  
    integer, dimension(:) :: start
    integer, dimension(:) :: length
    integer,              :: root = 0
    integer               :: comm_rank
    integer               :: comm_size
    integer               :: lsize
    
    lsize = 100
   
    call mpi_comm_rank(my_proc%comp_comm(ID), comm_rank, ierr)
    call mpi_comm_size(my_proc%comp_comm(ID), comm_size, ierr)

    allocate(start(1))
    allocate(length(1))

    start(1) = rank*(lsize/comm_size)
    length(1) = lsize - (rank)*(lsize/comm_size)

    call gsMap_init(gsMap_aa, start, length, root, my_proc%comp_comm(ID), ID)
    
    call avect_init(a2x, iList=fld_ia, rList=fld_ra, lsize=length(1))
    call avect_init(x2a, iList=fld_ia, rList=fld_ra, lsize=length(1))
   
    call avect_zero(a2x)
    call avect_zero(x2a) 

end subroutine a_init_mct

subroutine a_run_mct(my_proc, ID, EClock, a2x, x2a, ierr)

    implicit none
    type(proc), intent(inout)      :: my_proc
    integer,    intent(in)         :: ID
    type(Clock), intent(in)        :: EClock
    type(AttrVect), intent(inout)  :: a2x
    type(AttrVect), intent(inout)  :: x2a
    integer, intent(inout)         :: ierr    

    write(*,*) 'a_run'

end subroutine a_run_mct

subroutine a_final_mct()

end subroutine a_final_mct


end module comp_a