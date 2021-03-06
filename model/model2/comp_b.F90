module comp_b
use mct_mod
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
    public :: b_init_mct
    public :: b_run_mct
    public :: b_final_mct

contains

!-------------------------------------------------------------------------
!  a_init_mct, init gsmap_aa, avect, avect init with zero, but not init
!  dom at present
!-------------------------------------------------------------------------
subroutine b_init_mct(my_proc, ID, EClock, gsMap_bb, b2x_bb, x2b_bb, domain,ierr)

    implicit none
    type(proc), intent(inout)        :: my_proc
    integer, intent(in)              :: ID
    type(Clock), intent(in)          :: EClock
    type(gsMap), intent(inout)       :: gsMap_bb
    type(AttrVect), intent(inout)    :: b2x_bb
    type(AttrVect), intent(inout)    :: x2b_bb
    type(gGrid), intent(inout)              :: domain
    integer,  intent(inout)          :: ierr
  
    integer, allocatable  :: start(:)
    integer, allocatable  :: length(:)
    integer               :: root = 0
    integer               :: comm_rank
    integer               :: comm_size
    integer               :: lsize,gsize
    
   
    call mpi_comm_rank(my_proc%comp_comm(ID), comm_rank, ierr)
    call mpi_comm_size(my_proc%comp_comm(ID), comm_size, ierr)

    allocate(start(1))
    allocate(length(1))

    gsize = my_proc%b_gsize
    lsize = gsize / comm_size
    start(1) = comm_rank * lsize
    length(1) = lsize

    call gsMap_init(gsMap_bb, start, length, root, my_proc%comp_comm(ID), ID)
    
    call avect_init(b2x_bb, iList=fld_ai, rList=fld_ar, lsize=length(1))
    call avect_init(x2b_bb, iList=fld_ai, rList=fld_ar, lsize=length(1))
   
    call avect_zero(b2x_bb)
    call avect_zero(x2b_bb) 

end subroutine b_init_mct

subroutine b_run_mct(my_proc, ID, EClock, b2x, x2b, ierr)

    implicit none
    type(proc), intent(inout)      :: my_proc
    integer,    intent(in)         :: ID
    type(Clock), intent(in)        :: EClock
    type(AttrVect), intent(inout)  :: b2x
    type(AttrVect), intent(inout)  :: x2b
    integer, intent(inout)         :: ierr    
    integer comm_rank,i, av_lsize
    !write(*,*) 'b_run'
    
    call mpi_comm_rank(my_proc%comp_comm(ID), comm_rank, ierr)
    
!    call MPI_Barrier(my_proc%comp_comm(ID), ierr)
        av_lsize = avect_lsize(b2x) 
!        write(*,*) '<<========I am Model_B Rank:',comm_rank,' Avlsize:',av_lsize,& 
!        ' Run(ADD 100*rank) ===========>>'
!    call MPI_Barrier(my_proc%comp_comm(ID), ierr)

    do i=1,av_lsize
        b2x%rAttr(1,i) = x2b%rAttr(1,i) + 100*(comm_rank+1)
    enddo

!    call MPI_Barrier(my_proc%comp_comm(ID), ierr)
!        write(*,*) '<<===A2X_AA_VALUE Rank:',comm_rank, a2x%rAttr(1,:)
!    call MPI_Barrier(my_proc%comp_comm(ID), ierr)

end subroutine b_run_mct

subroutine b_final_mct()

end subroutine b_final_mct


end module comp_b
