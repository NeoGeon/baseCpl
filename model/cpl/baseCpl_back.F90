module baseCpl
use proc_def 
use comms_def
use procm, only: pm_init => init, clean
use comms
use timeM
use mct_mod
use comp_a
use comp_c
use comp_b

     implicit none
     type(proc), target :: my_proc
	
    ! Declare gsMap of each Model
	 type(gsMap) :: gsMap_aa
	 type(gsMap) :: gsMap_ax
	 type(gsMap) :: gsMap_cc
	 type(gsMap) :: gsMap_cx
	 type(gsMap) :: gsMap_bb
	 type(gsMap) :: gsMap_bx

    ! Declare AttrVect of each Model(c2x_cx,c2x_cc,x2c_cx,x2c_cc)
	 type(AttrVect),pointer ::a2x_aa
	 type(AttrVect),pointer ::a2x_ax
	 type(AttrVect),pointer ::x2a_aa
	 type(AttrVect),pointer ::x2a_ax
	 type(AttrVect),pointer ::c2x_cc
	 type(AttrVect),pointer ::c2x_cx
	 type(AttrVect),pointer ::x2c_cc
	 type(AttrVect),pointer ::x2c_cx
	 type(AttrVect),pointer ::b2x_bb
	 type(AttrVect),pointer ::b2x_bx
	 type(AttrVect),pointer ::x2b_bb
	 type(AttrVect),pointer ::x2b_bx


    ! Declare Temp Merge AttrVect of each Model(m2x_nx)
	 type(AttrVect):: a2x_bx
	 type(AttrVect):: a2x_cx
	 type(AttrVect):: c2x_bx
	 type(AttrVect):: c2x_ax
	 type(AttrVect):: b2x_cx
	 type(AttrVect):: b2x_ax

    ! Declare Control Var
	 logical :: a_run
	 logical :: c_run
	 logical :: b_run

    
     logical :: stop_clock
     type(clock) :: EClock
 
     public :: cpl_init
     public :: cpl_run
     public :: cpl_final
   !test
     integer :: fhandle,fin,filetype,ngseg
     !type(mpi_file) :: fhandle
     real(8),dimension(2) :: tmp_data
     integer, dimension(MPI_STATUS_SIZE) :: status
    integer, dimension(2) :: arraysize, arraystart
    integer, dimension(2) :: arraygsize, arraysubsize
    integer, dimension(:),pointer :: points
    INTEGER(KIND=MPI_OFFSET_KIND) :: offset
     character(len=4) :: msg
contains

subroutine cpl_init()
    implicit none
    integer :: ierr
    integer :: comm_rank
    call pm_init(my_proc)
    call clock_init(EClock)
    
    !---
    ! !A in 0,1,gsize=8   B in 2,3,gsize=12   C in 2,3,gsize=16
    ! !Cpl in 0,1,2,3
	!----
	
    !-------------------------------------------------------------------
    !  !Define Model_AV_MM 
    !-------------------------------------------------------------------
    
		a2x_aa=> my_proc%a2x_aa
		a2x_ax=> my_proc%a2x_ax
		x2a_aa=> my_proc%x2a_aa
		x2a_ax=> my_proc%x2a_ax
		c2x_cc=> my_proc%c2x_cc
		c2x_cx=> my_proc%c2x_cx
		x2c_cc=> my_proc%x2c_cc
		x2c_cx=> my_proc%x2c_cx
		b2x_bb=> my_proc%b2x_bb
		b2x_bx=> my_proc%b2x_bx
		x2b_bb=> my_proc%x2b_bb
		x2b_bx=> my_proc%x2b_bx

    call MPI_Comm_rank(MPI_COMM_WORLD, comm_rank, ierr)


	!-------------------------------------------------------------------
    ! !Model Init
    !-------------------------------------------------------------------
		if(my_proc%iamin_modela)then
			call a_init_mct(gsMap_aa=gsMap_aa,my_proc=my_proc,x2a_aa=x2a_aa,ierr=ierr,a2x_aa=a2x_aa,ID=my_proc%modela_id,EClock=EClock)
		end if
		if(my_proc%iamin_modelc)then
			call c_init_mct(my_proc=my_proc,x2c_cc=x2c_cc,gsMap_cc=gsMap_cc,c2x_cc=c2x_cc,ierr=ierr,ID=my_proc%modelc_id,EClock=EClock)
		end if
		if(my_proc%iamin_modelb)then
			call b_init_mct(my_proc=my_proc,ierr=ierr,ID=my_proc%modelb_id,b2x_bb=b2x_bb,gsMap_bb=gsMap_bb,x2b_bb=x2b_bb,EClock=EClock)
		end if

    
    call MPI_Barrier(MPI_COMM_WORLD, ierr)
		write(*,*) '<<==== All Model Init Rank:', comm_rank, &
		" Over ====>>"
    call MPI_Barrier(MPI_COMM_WORLD, ierr)
        write(*,*) ' '
    call MPI_Barrier(MPI_COMM_WORLD, ierr)
    
	
	!-------------------------------------------------------------------
    ! !Model_X gsmap_ext av_ext
    !-------------------------------------------------------------------
		if(my_proc%iamin_modela2cpl)then
			call gsmap_init_ext(my_proc, gsMap_aa, &
								my_proc%modela_id, &
								gsMap_ax, my_proc%cplid, &
								my_proc%modela2cpl_id )

			call avect_init_ext(my_proc, a2x_aa,&
						my_proc%modela_id, a2x_ax, &
						my_proc%cplid, gsMap_ax, &
						my_proc%modela2cpl_id)

			call avect_init_ext(my_proc, x2a_aa,&
						my_proc%modela_id, x2a_ax, &
						my_proc%cplid, gsMap_ax, &
						my_proc%modela2cpl_id)
			call mapper_rearrsplit_init(my_proc%mapper_Ca2x, &
					my_proc, gsMap_aa, my_proc%modela_id, &
					gsMap_ax, my_proc%cplid, &
					my_proc%modela2cpl_id, ierr)

			call mapper_rearrsplit_init(my_proc%mapper_Cx2a, &
					my_proc, gsMap_ax, my_proc%cplid, &
					gsMap_aa, my_proc%modela_id, &
					my_proc%modela2cpl_id, ierr)

			call MPI_Barrier(my_proc%mpi_modela2cpl, ierr)
			call mapper_comp_map(my_proc%mapper_Ca2x, &
					a2x_aa, a2x_ax, 100+10+1, ierr)
		end if
		if(my_proc%iamin_modelc2cpl)then
			call gsmap_init_ext(my_proc, gsMap_cc, &
								my_proc%modelc_id, &
								gsMap_cx, my_proc%cplid, &
								my_proc%modelc2cpl_id )

			call avect_init_ext(my_proc, c2x_cc,&
						my_proc%modelc_id, c2x_cx, &
						my_proc%cplid, gsMap_cx, &
						my_proc%modelc2cpl_id)

			call avect_init_ext(my_proc, x2c_cc,&
						my_proc%modelc_id, x2c_cx, &
						my_proc%cplid, gsMap_cx, &
						my_proc%modelc2cpl_id)
			call mapper_rearrsplit_init(my_proc%mapper_Cc2x, &
					my_proc, gsMap_cc, my_proc%modelc_id, &
					gsMap_cx, my_proc%cplid, &
					my_proc%modelc2cpl_id, ierr)

			call mapper_rearrsplit_init(my_proc%mapper_Cx2c, &
					my_proc, gsMap_cx, my_proc%cplid, &
					gsMap_cc, my_proc%modelc_id, &
					my_proc%modelc2cpl_id, ierr)

			call MPI_Barrier(my_proc%mpi_modelc2cpl, ierr)
			call mapper_comp_map(my_proc%mapper_Cc2x, &
					c2x_cc, c2x_cx, 100+10+1, ierr)
		end if
		if(my_proc%iamin_modelb2cpl)then
			call gsmap_init_ext(my_proc, gsMap_bb, &
								my_proc%modelb_id, &
								gsMap_bx, my_proc%cplid, &
								my_proc%modelb2cpl_id )

			call avect_init_ext(my_proc, b2x_bb,&
						my_proc%modelb_id, b2x_bx, &
						my_proc%cplid, gsMap_bx, &
						my_proc%modelb2cpl_id)

			call avect_init_ext(my_proc, x2b_bb,&
						my_proc%modelb_id, x2b_bx, &
						my_proc%cplid, gsMap_bx, &
						my_proc%modelb2cpl_id)
			call mapper_rearrsplit_init(my_proc%mapper_Cb2x, &
					my_proc, gsMap_bb, my_proc%modelb_id, &
					gsMap_bx, my_proc%cplid, &
					my_proc%modelb2cpl_id, ierr)

			call mapper_rearrsplit_init(my_proc%mapper_Cx2b, &
					my_proc, gsMap_bx, my_proc%cplid, &
					gsMap_bb, my_proc%modelb_id, &
					my_proc%modelb2cpl_id, ierr)

			call MPI_Barrier(my_proc%mpi_modelb2cpl, ierr)
			call mapper_comp_map(my_proc%mapper_Cb2x, &
					b2x_bb, b2x_bx, 100+10+1, ierr)
		end if


    call MPI_Barrier(MPI_COMM_WORLD, ierr)
    write(6,*) '<<========= Rank:',comm_rank,' Model-XInit End====>>'
    call MPI_Barrier(MPI_COMM_WORLD, ierr)
            write(*,*) ' '
    call MPI_Barrier(MPI_COMM_WORLD, ierr)


    if(my_proc%iamin_cpl) then

			call avect_init_ext(my_proc, a2x_ax,&
						 my_proc%cplid, a2x_bx,&
						 my_proc%cplid, gsMap_bx,&
						 my_proc%modelb2cpl_id)

			call mapper_spmat_init(my_proc,&
					my_proc%mapper_SMata2b, &
					my_proc%cplid, &
					my_proc%b_gsize, my_proc%a_gsize, &
                    8,&
					gsMap_ax, gsMap_bx)

			call avect_init_ext(my_proc, a2x_ax,&
						 my_proc%cplid, a2x_cx,&
						 my_proc%cplid, gsMap_cx,&
						 my_proc%modelc2cpl_id)

			call mapper_spmat_init(my_proc,&
					my_proc%mapper_SMata2c, &
					my_proc%cplid, &
					my_proc%c_gsize, my_proc%a_gsize, &
                    8,&
					gsMap_ax, gsMap_cx)

			call avect_init_ext(my_proc, c2x_cx,&
						 my_proc%cplid, c2x_bx,&
						 my_proc%cplid, gsMap_bx,&
						 my_proc%modelb2cpl_id)

			call mapper_spmat_init(my_proc,&
					my_proc%mapper_SMatc2b, &
					my_proc%cplid, &
					my_proc%b_gsize, my_proc%c_gsize, &
                    8,&
					gsMap_cx, gsMap_bx)

			call avect_init_ext(my_proc, c2x_cx,&
						 my_proc%cplid, c2x_ax,&
						 my_proc%cplid, gsMap_ax,&
						 my_proc%modela2cpl_id)

			call mapper_spmat_init(my_proc,&
					my_proc%mapper_SMatc2a, &
					my_proc%cplid, &
					my_proc%a_gsize, my_proc%c_gsize, &
                    8,&
					gsMap_cx, gsMap_ax)

			call avect_init_ext(my_proc, b2x_bx,&
						 my_proc%cplid, b2x_cx,&
						 my_proc%cplid, gsMap_cx,&
						 my_proc%modelc2cpl_id)

			call mapper_spmat_init(my_proc,&
					my_proc%mapper_SMatb2c, &
					my_proc%cplid, &
					my_proc%c_gsize, my_proc%b_gsize, &
                    8,&
					gsMap_bx, gsMap_cx)

			call avect_init_ext(my_proc, b2x_bx,&
						 my_proc%cplid, b2x_ax,&
						 my_proc%cplid, gsMap_ax,&
						 my_proc%modela2cpl_id)

			call mapper_spmat_init(my_proc,&
					my_proc%mapper_SMatb2a, &
					my_proc%cplid, &
					my_proc%a_gsize, my_proc%b_gsize, &
                    8,&
					gsMap_bx, gsMap_ax)

        call MPI_Barrier(MPI_COMM_WORLD, ierr)
        write(*,*) "<<=== Rank:" , comm_rank, &
            " lb2x_ax:", avect_lsize(b2x_ax),&
            " lc2x_ax:", avect_lsize(c2x_ax),&
            " la2x_bx:", avect_lsize(a2x_bx),&
            " lc2x_bx:", avect_lsize(c2x_bx),&
            " la2x_cx:", avect_lsize(a2x_cx),&
            " lb2x_cx:", avect_lsize(b2x_cx),&
            "===>>"
        call MPI_Barrier(MPI_COMM_WORLD, ierr)
        write(*,*) " "
        call MPI_Barrier(MPI_COMM_WORLD, ierr)
	end if
    write(*,*)'<========= Init End  ===========>'
    call MPI_Barrier(MPI_COMM_WORLD, ierr)

end subroutine cpl_init

subroutine cpl_run()

    implicit none
    integer :: ierr,s,i,comm_rank
    
    call mpi_comm_rank(my_proc%comp_comm(my_proc%gloid), comm_rank, ierr)
    call MPI_Barrier(MPI_COMM_WORLD, ierr)
    write(*,*) '<<============== Rank:',comm_rank,' Begin Run==================>>'
    call MPI_Barrier(MPI_COMM_WORLD, ierr)
            write(*,*) ' '
    call MPI_Barrier(MPI_COMM_WORLD, ierr)
    s = 0

    call triger(EClock, stop_clock, "stop_clock")
    do while(.not. stop_clock)

        call clock_advance(EClock)
        call triger(EClock, a_run, "a_run")
        call triger(EClock, c_run, "c_run")
        call triger(EClock, b_run, "b_run")
        call triger(EClock, stop_clock, "stop_clock")
        s = s+1
        if(s==10) stop_clock = .true.



        !------------------------------------------------------------
        !  Run phase 1 X2M_MX --> X2M_MM
        !  (M is Model, X is CPL)
        !------------------------------------------------------------


        if(a_run)then
            if(my_proc%iamin_modela2cpl)then
				if(s == 3 .and. my_proc%iamin_modela2cpl) then
					do i=1,avect_lsize(x2a_ax)
					x2a_ax%rAttr(1,i) = x2a_ax%rAttr(1,i) + (comm_rank+1)*10+i
					enddo
				endif
				if(s == 7 .and. my_proc%iamin_modelb2cpl) then
					do i=1,avect_lsize(x2b_bx)
						x2b_bx%rAttr(1,i) = x2b_bx%rAttr(1,i) + (comm_rank+1)*10+i
					enddo
				endif
                
					call mapper_comp_map(mapper=my_proc%Mapper_Cx2a,rList='x',src=x2a_ax,dst=x2a_aa,msgtag=100+10+2,ierr=ierr)

                if(s == 3 .and. my_proc%iamin_modela2cpl) then
                    call MPI_Barrier(my_proc%comp_comm(my_proc%modela2cpl_id), ierr)
                    write(*,*) '<<===X2A_AA_VALUE Rank:',comm_rank, x2a_aa%rAttr(1,:)
                call MPI_Barrier(my_proc%comp_comm(my_proc%modela2cpl_id), ierr)
                end if
            end if
        end if
        if(c_run)then
            if(my_proc%iamin_modelc2cpl)then
				if(s == 3 .and. my_proc%iamin_modela2cpl) then
					do i=1,avect_lsize(x2a_ax)
					x2a_ax%rAttr(1,i) = x2a_ax%rAttr(1,i) + (comm_rank+1)*10+i
					enddo
				endif
				if(s == 7 .and. my_proc%iamin_modelb2cpl) then
					do i=1,avect_lsize(x2b_bx)
						x2b_bx%rAttr(1,i) = x2b_bx%rAttr(1,i) + (comm_rank+1)*10+i
					enddo
				endif
                
					call mapper_comp_map(mapper=my_proc%Mapper_Cx2c,rList='x',src=x2c_cx,dst=x2c_cc,msgtag=100+10+2,ierr=ierr)

                if(s == 3 .and. my_proc%iamin_modela2cpl) then
                    call MPI_Barrier(my_proc%comp_comm(my_proc%modela2cpl_id), ierr)
                    write(*,*) '<<===X2A_AA_VALUE Rank:',comm_rank, x2a_aa%rAttr(1,:)
                call MPI_Barrier(my_proc%comp_comm(my_proc%modela2cpl_id), ierr)
                end if
            end if
        end if
        if(b_run)then
            if(my_proc%iamin_modelb2cpl)then
				if(s == 3 .and. my_proc%iamin_modela2cpl) then
					do i=1,avect_lsize(x2a_ax)
					x2a_ax%rAttr(1,i) = x2a_ax%rAttr(1,i) + (comm_rank+1)*10+i
					enddo
				endif
				if(s == 7 .and. my_proc%iamin_modelb2cpl) then
					do i=1,avect_lsize(x2b_bx)
						x2b_bx%rAttr(1,i) = x2b_bx%rAttr(1,i) + (comm_rank+1)*10+i
					enddo
				endif
                
					call mapper_comp_map(mapper=my_proc%Mapper_Cx2b,rList='x',src=x2b_bx,dst=x2b_bb,msgtag=100+10+2,ierr=ierr)

                if(s == 3 .and. my_proc%iamin_modela2cpl) then
                    call MPI_Barrier(my_proc%comp_comm(my_proc%modela2cpl_id), ierr)
                    write(*,*) '<<===X2A_AA_VALUE Rank:',comm_rank, x2a_aa%rAttr(1,:)
                call MPI_Barrier(my_proc%comp_comm(my_proc%modela2cpl_id), ierr)
                end if
            end if
        end if

        call MPI_Barrier(MPI_COMM_WORLD, ierr)


        !------------------------------------------------------------
        !  Run phase 2, Model Run,  X2M_MM --> M2X_MM
        !  (M is Model, X is CPL)
        !------------------------------------------------------------

        if(a_run)then
            if(my_proc%iamin_modela)then
				call a_run_mct(my_proc=my_proc,a2x=a2x_aa,x2a=x2a_aa,ierr=ierr,ID=my_proc%modela_id,EClock=EClock)
            end if
        end if
        if(c_run)then
            if(my_proc%iamin_modelc)then
				call c_run_mct(my_proc=my_proc,c2x=c2x_cc,ierr=ierr,x2c=x2c_cc,ID=my_proc%modelc_id,EClock=EClock)
            end if
        end if
        if(b_run)then
            if(my_proc%iamin_modelb)then
				call b_run_mct(my_proc=my_proc,b2x=b2x_bb,ierr=ierr,x2b=x2b_bb,ID=my_proc%modelb_id,EClock=EClock)
            end if
        end if

        call MPI_Barrier(MPI_COMM_WORLD, ierr)
                    write(*,*)
        call MPI_Barrier(MPI_COMM_WORLD, ierr)

        !------------------------------------------------------------
        !  Run phase 3
        !  For each Model:
        !  Step1: Rearrange, M2X_MM --> M2X_MX
        !  Step2: SparseMul With Other Model, M2X_MX --> M2X_BX
        !  (M is Model, X is CPL, B is Another Model)
        !------------------------------------------------------------
        !  For example:
        ! rearrage(a2x_aa,b2x_bb,c2x_cc) => (a2x_ax,b2x_bx,c2x_cx)
        ! sparse(a2x_ax b2x_bx c2x_cx) =>
        ! (a2x_bx,a2x_cx) (b2x_cx,b2x_a2) (c2x_ax,c2x_bx)
        !
   
        if(a_run)then
            if(my_proc%iamin_modela2cpl)then
				call mapper_comp_map(mapper=my_proc%Mapper_Ca2x,rList='x',src=a2x_aa,dst=a2x_ax,msgtag=100+10+3,ierr=ierr)
call mapper_comp_map(mapper=my_proc%mapper_SMata2b,rList='x',src=a2x_ax,dst=a2x_bx,msgtag=100+10+3,ierr=ierr)
call mapper_comp_map(mapper=my_proc%mapper_SMata2c,rList='x',src=a2x_ax,dst=a2x_cx,msgtag=100+10+3,ierr=ierr)
            end if
        end if
        if(c_run)then
            if(my_proc%iamin_modelc2cpl)then
				call mapper_comp_map(mapper=my_proc%Mapper_Cc2x,rList='x',src=c2x_cc,dst=c2x_cx,msgtag=100+10+3,ierr=ierr)
call mapper_comp_map(mapper=my_proc%mapper_SMatc2b,rList='x',src=c2x_cx,dst=c2x_bx,msgtag=100+10+3,ierr=ierr)
call mapper_comp_map(mapper=my_proc%mapper_SMatc2a,rList='x',src=c2x_cx,dst=c2x_ax,msgtag=100+10+3,ierr=ierr)
            end if
        end if
        if(b_run)then
            if(my_proc%iamin_modelb2cpl)then
				call mapper_comp_map(mapper=my_proc%Mapper_Cb2x,rList='x',src=b2x_bb,dst=b2x_bx,msgtag=100+10+3,ierr=ierr)
call mapper_comp_map(mapper=my_proc%mapper_SMatb2c,rList='x',src=b2x_bx,dst=b2x_cx,msgtag=100+10+3,ierr=ierr)
call mapper_comp_map(mapper=my_proc%mapper_SMatb2a,rList='x',src=b2x_bx,dst=b2x_ax,msgtag=100+10+3,ierr=ierr)
            end if
        end if
	
        !------------------------------------------------------------
        !  Run phase 4
        !  Merge (A2X_MX, B2X_MX, C2X_MX, M2X_MX)--> X2M_MX
        !  (M is Model, X is CPL, A,B,C is Another Model)
        !------------------------------------------------------------
        ! For Example:
        ! (c2x_ax,b2x_ax,a2x_ax) => (x2a_ax)
        ! (c2x_bx,b2x_bx,a2x_bx) => (x2b_bx)
        ! (c2x_cx,b2x_cx,a2x_cx) => (x2c_cx)
    if(my_proc%iamin_cpl) then
        if(s==10) then
            ! merge *2x_ax --> x2a_ax in rfield "x", cal the mean of all
            call mapper_comp_avMerge(a2x_ax, b2x_ax, c2x_ax, x2a_ax, "x")
            call MPI_Barrier(my_proc%comp_comm(my_proc%modela2cpl_id), ierr)
                    write(*,*) '<<===X2A_AX_Merge_VALUE Rank:',comm_rank, x2a_ax%rAttr(1,:)
                !call mrg_a(a2x_ax, b2x_ax, c2x_ax)
            call MPI_Barrier(my_proc%comp_comm(my_proc%modela2cpl_id), ierr)
        endif
    endif
    
    if(my_proc%iamin_modela2cpl) then
        if(s==10) then

        call MPI_File_Open(my_proc%mpi_modela2cpl, "file.txt", MPI_MODE_RDONLY, MPI_INFO_NULL, fin, ierr)
        if (ierr /= MPI_SUCCESS) write(*,*) 'Open read error on rank ', comm_rank

        offset = comm_rank*2*8
        
        ngseg = gsMap_lsize(gsMap_ax, my_proc%mpi_modela2cpl)        
        call gsMap_order(gsMap_ax,comm_rank,points)
            write(*,*) 'rank_', comm_rank, points, ngseg
        call MPI_Barrier(my_proc%mpi_modela2cpl, ierr)
        
        do i=1,ngseg
        offset = points(i) * 8
        call MPI_File_Read_At(fin, &
                            offset,&
                            tmp_data(i), 1, MPI_DOUBLE_PRECISION &
                             , status, ierr)
        end do

        if (ierr /= MPI_SUCCESS) write(*,*) 'read error on rank ', comm_rank

        do i=1,2
         write(*,*) ' read rank',comm_rank, ' i',i,  tmp_data(i)
        call MPI_Barrier(my_proc%mpi_modela2cpl, ierr)
        end do

        call MPI_File_Close(fin, ierr)
        call save_model_av(my_proc, x2a_ax, gsMap_ax, my_proc%modela2cpl_id, s)
        if(comm_rank == 0) msg = "1230"
        if(comm_rank == 1) msg = "1231"
        if(comm_rank == 2) msg = "1232"
        if(comm_rank == 3) msg = "1233"
        !call log_msg(my_proc,my_proc%modela2cpl_id, msg,"file2.txt" )
!        call MPI_File_Open(my_proc%mpi_modela2cpl, "file.txt", MPI_MODE_WRONLY + MPI_MODE_CREATE, MPI_INFO_NULL, fhandle, ierr)
!        if (ierr /= MPI_SUCCESS) write(*,*) 'Open error on rank ', comm_rank
!
!        do i=1,2
!        tmp_data(i) = x2a_ax%rAttr(1,i)
!         write(*,*) 'write rank',comm_rank, ' i',i,  tmp_data(i), offset
!        call MPI_Barrier(my_proc%mpi_modela2cpl, ierr)
!        end do
!
!        do i=1,ngseg
!        offset = points(i) * 8
!        call MPI_File_Write_At(fhandle,&
!                             offset, &
!                             x2a_ax%rAttr(1,i), 1, MPI_DOUBLE_PRECISION &
!                             , status, ierr)
!        end do
!        !end if
!
!        if (ierr /= MPI_SUCCESS) write(*,*) 'Write error on rank ', comm_rank, ' ', offset
!        call MPI_File_Close(fhandle, ierr)
        endif
        call log_run_msg(my_proc,my_proc%modela2cpl_id, "file2.txt" , s) !LOG TEST
        if(s == 10 .and. comm_rank == 0) then
            write(*,*) x2a_ax%rAttr(1,:)
            write(*,*) x2a_ax%rAttr(2,:)
            write(*,*) x2a_ax%iAttr(1,:)
            write(*,*) x2a_ax%iAttr(2,:)
            write(*,*) x2a_ax%iAttr(3,:)
            call write_netcdf(my_proc, my_proc%modela2cpl_id, "netcf.nc", s, x2a_ax, gsMap_ax)
            call read_netcdf(my_proc, my_proc%modela2cpl_id, "netcf.nc", s, x2a_ax, gsMap_ax)
        end if
    endif

    end do

end subroutine cpl_run

subroutine cpl_final()

    implicit none

    !----------------------------------------------------------------------
    !     end component
    !----------------------------------------------------------------------
    if(my_proc%iamin_modela)then
			call a_final_mct()
    end if
    if(my_proc%iamin_modelc)then
			call c_final_mct()
    end if
    if(my_proc%iamin_modelb)then
			call b_final_mct()
    end if
    call clean(my_proc)

end subroutine cpl_final

end module baseCpl
