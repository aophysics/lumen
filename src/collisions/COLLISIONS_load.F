!
!        Copyright (C) 2000-2016 the YAMBO team
!              http://www.yambo-code.org
!
! Authors (see AUTHORS file for details): AM CA
! 
! This file is distributed under the terms of the GNU 
! General Public License. You can redistribute it and/or 
! modify it under the terms of the GNU General Public 
! License as published by the Free Software Foundation; 
! either version 2, or (at your option) any later version.
!
! This program is distributed in the hope that it will 
! be useful, but WITHOUT ANY WARRANTY; without even the 
! implied warranty of MERCHANTABILITY or FITNESS FOR A 
! PARTICULAR PURPOSE.  See the GNU General Public License 
! for more details.
!
! You should have received a copy of the GNU General Public 
! License along with this program; if not, write to the Free 
! Software Foundation, Inc., 59 Temple Place - Suite 330,Boston, 
! MA 02111-1307, USA or visit http://www.gnu.org/copyleft/gpl.txt.
!
subroutine COLLISIONS_load(CHECK_EXISTENCE_ONLY)
 !
 ! Load all collisions contribution from any kind of self-energy 
 ! exchange, COHSEX etc.. 
 !
 use drivers,         ONLY:l_sc_hf,l_sc_cohsex,l_sc_exx,l_use_collisions,l_sc_srpa,&
&                          l_elel_scatt,l_elphoton_scatt,l_elphoton_corr
 use LIVE_t,          ONLY:live_timing
 use QP_m,            ONLY:QP_n_states,QP_QED_ng,QP_table
 use R_lattice,       ONLY:nqbz
 use global_XC,       ONLY:SC_Fock,SC_COHSEX,SE_GW_NEQ
 use collision,       ONLY:COLL_bands
 use collision,       ONLY:V_kind,SEX_collisions,Fock_collisions,n_COLLISIONS,COLLISIONS_state
 use IO_m,            ONLY:OP_RD,RD_CL,OP_RD_CL,io_control,VERIFY,REP
 use parallel_m,      ONLY:PAR_nQP,PAR_QP_index,PAR_IND_QP,PAR_IND_Q,&
&                          PAR_nQ,PAR_Q_index,PP_redux_wait,PAR_COM_Xk_ibz_INDEX
 use interfaces,      ONLY:io_COLLISIONS
 use electrons,       ONLY:spin
 use stderr,          ONLY:intc
 use com,             ONLY:warning,error
 !
 implicit none
 !
 logical            :: CHECK_EXISTENCE_ONLY
 !
 ! Parameters
 !
 integer, parameter :: max_V_kinds=10
 !
 ! Work Space
 !
 integer            :: iqbz,i_J,ic,i_qp,ID,io_err(max_V_kinds),V_kinds(max_V_kinds),n_V_kinds,&
&                      iv,i_qp_mem,i_q_mem,i_J_mem,i_b,i_g,state(4),i_db
 logical            :: condition
 integer            :: DB_table(QP_n_states) ! Table pointing to the COLLISION DB
 !
 n_V_kinds   =0
 io_err      =0
 V_kinds     =0
 !
 condition=l_sc_hf.or.l_sc_cohsex.or.l_sc_exx
 if (condition) then
   n_V_kinds          =n_V_kinds+1
   V_kinds(n_V_kinds) =SC_Fock
 endif
 !
 condition=l_sc_cohsex.or.l_sc_srpa
 if (condition) then
   n_V_kinds          =n_V_kinds+1
   V_kinds(n_V_kinds) =SC_COHSEX
 endif
 !
 if (n_V_kinds==0) return
 !
 ! Check only if the DB exist and are readable
 !
 if (CHECK_EXISTENCE_ONLY) then
   !
   do iv=1,n_V_kinds
     !
     V_kind=V_kinds(iv)
     !
     call io_control(ACTION=OP_RD_CL,COM=REP,MODE=VERIFY,SEC=(/1/),ID=ID)
     io_err(iv)=io_COLLISIONS(0,ID)
     !
   enddo
   !
   l_use_collisions=all(io_err==0)
   !
   return
   !
 endif
 !
 if (.not.l_use_collisions) return
 !
 if (n_COLLISIONS/=QP_n_states) then
   call warning('Found '//trim(intc(n_COLLISIONS))//' COLLISION components. Only '//trim(intc(QP_n_states))//' requested.')
   if (n_COLLISIONS<QP_n_states) then
     call error('Not enough COLLISION components')
   endif
 endif
 !
 DB_table=0
 if(allocated(COLLISIONS_state)) then
   do i_qp=1,QP_n_states
     state(:3)=QP_table(i_qp,:3)
     state( 4)=spin(QP_table(i_qp,:))
     do i_db=1,n_COLLISIONS
       if (all(state(:)==COLLISIONS_state(i_db,:))) DB_table(i_qp)=i_db
     enddo
     if (DB_table(i_qp)==0) call error('COLLISION components #'//trim(intc(i_qp))//' not found')
   enddo
 else
   do i_qp=1,QP_n_states
     DB_table(i_qp)=i_qp
   enddo
 endif
 !
 call live_timing('Collisions DB I/O:',PAR_nQP*n_V_kinds)
 !
 do iv=1,n_V_kinds
   !
   V_kind=V_kinds(iv)
   !
   if (V_kind==SC_Fock)     call COLLISIONS_alloc_and_free("Fock","collision","alloc",0)
   if (V_kind==SC_COHSEX)   call COLLISIONS_alloc_and_free("SEX","collision","alloc",0)
   !
   do i_qp=1,QP_n_states
     !
     if (.not.PAR_IND_QP%element_1D(i_qp)) cycle
     !
     i_qp_mem=PAR_QP_index(i_qp)
     i_db    =DB_table(i_qp)
     !
     call io_control(ACTION=OP_RD,SEC=(/1,2/),ID=ID)
     !
     if (V_kind==SC_Fock) then
       io_err(iv)=io_COLLISIONS(i_db,ID,Fock_collisions(i_qp_mem))
       call COLLISIONS_alloc_and_free("Fock","v1 table","alloc",i_qp_mem)
     endif
     if (V_kind==SC_COHSEX) then
       io_err(iv)=io_COLLISIONS(i_db,ID,SEX_collisions(i_qp_mem))
       call COLLISIONS_alloc_and_free("SEX","v1 table","alloc",i_qp_mem)
     endif
     !
     call io_control(ACTION=RD_CL,SEC=(/3/),ID=ID)
     !
     if (V_kind==SC_Fock)     io_err(iv)=io_COLLISIONS(i_db,ID,Fock_collisions(i_qp_mem))
     if (V_kind==SC_COHSEX)   io_err(iv)=io_COLLISIONS(i_db,ID,SEX_collisions(i_qp_mem))
     !
     ! Now the transfer %v_r => %v3_r
     !
     call live_timing(steps=1)
     !
   end do
   !
 enddo
 !
 call PP_redux_wait(COMM=PAR_COM_Xk_ibz_INDEX%COMM)
 !
 call live_timing()
 !
end subroutine COLLISIONS_load
