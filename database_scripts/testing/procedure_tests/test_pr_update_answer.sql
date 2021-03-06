use HAN_SQL_EXAM_DATABASE
go

tSQLt.NewTestClass 'test_pr_update_answer'
go

create or alter proc test_pr_update_answer.test_if_pr_throws_when_exam_id_is_null
as
begin
	exec tSQLt.ExpectException @ExpectedMessagePattern = '%exam_id cannot be null%'

	exec pr_update_answer @student_no = 1, @exam_id = null, @question_no = 1, @answer = 'select  from chairs'
end
go

create or alter proc test_pr_update_answer.test_if_pr_throws_when_student_no_is_null
as
begin
	exec tSQLt.ExpectException @ExpectedMessagePattern = '%student_no cannot be NULL%'

	exec pr_update_answer @student_no = null, @exam_id = 'eId', @question_no = 1, @answer = 'select  from chairs'
end
go

create or alter proc test_pr_update_answer.test_if_pr_throws_when_question_no_is_null
as
begin
	exec tSQLt.ExpectException @ExpectedMessagePattern = '%question_no cannot be null%'

	exec pr_update_answer @student_no = 1, @exam_id = 'eId', @question_no = null, @answer = 'select  from chairs'
end
go

create or alter proc test_pr_update_answer.test_if_pr_throws_when_answer_is_null
as
begin
	exec tSQLt.ExpectException @ExpectedMessagePattern = '%answer cannot be null%'

	exec pr_update_answer @student_no = 1, @exam_id = 'eId', @question_no = 1, @answer = null
end
go

create or alter proc test_pr_update_answer.test_if_pr_throws_when_trying_to_insert_before_begin_date
as
begin
	exec tSQLt.FakeTable 'EXAM_GROUP_IN_EXAM'
	exec tSQLt.FakeTable 'EXAM_FOR_STUDENT'
	exec tSQLt.FakeTable 'EXAM'

	insert into EXAM_GROUP_IN_EXAM(exam_id, exam_group_type, end_date)
	values ('eId', 'Standaard', GETDATE()+140)

	insert into EXAM_FOR_STUDENT(exam_id, exam_group_type, student_no, class, result)
	values ('eId', 'Standaard', 1, 'cId', null)

	insert into EXAM values('eId', null, null, GETDATE()+120, NULL)

	exec tSQLt.ExpectException @ExpectedMessagePattern = '%An answer can only be modified while the exam is taking place%'

	exec pr_update_answer @student_no = 1, @exam_id = 'eId', @question_no = 1, @answer = 'select  from chairs'
end
go

create or alter proc test_pr_update_answer.test_if_pr_throws_when_trying_to_insert_after_end_date
as
begin
	exec tSQLt.FakeTable 'EXAM_GROUP_IN_EXAM'
	exec tSQLt.FakeTable 'EXAM_FOR_STUDENT'
	exec tSQLt.FakeTable 'EXAM'

	insert into EXAM_GROUP_IN_EXAM(exam_id, exam_group_type, end_date)
	values ('eId', 'Standaard', GETDATE()-120)

	insert into EXAM_FOR_STUDENT(exam_id, exam_group_type, student_no, class, result)
	values ('eId', 'Standaard', 1, 'cId', null)

	insert into EXAM values('eId', null, null, GETDATE()-220, NULL)

	exec tSQLt.ExpectException @ExpectedMessagePattern = '%An answer can only be modified while the exam is taking place%'

	exec pr_update_answer @student_no = 1, @exam_id = 'eId', @question_no = 1, @answer = 'select  from chairs'
end
go

create or alter proc test_pr_update_answer.test_if_pr_updates_correct_answer
as
begin
	declare @student_no int = 1
	declare @exam_id varchar(20) = 'eId'
	declare @question_no int = 1
	declare @answer_old varchar(max) = 'select  from chairs'
	declare @answer_new varchar(max) = 'select  from floors'
	declare @answer_fill_in_date datetime = getdate()

    exec tSQLt.FakeTable 'ANSWER'
    
	insert into ANSWER(exam_id, question_no, student_no, answer, answer_status, answer_fill_in_date, reason_no)
	values (@exam_id, @question_no, @student_no, @answer_old, 'REQUIRE CHECK', @answer_fill_in_date, null)

	create table expected (
		student_no			int				not null,
		exam_id				varchar(20)		not null,
		question_no			int				not null,
		reason_no			int				null,
		answer				varchar(max)	null,
		answer_status		varchar(50) 	not null,
		answer_fill_in_date	datetime		not null
	)
	
	insert into expected(exam_id, question_no, student_no, answer, answer_status, answer_fill_in_date, reason_no)
	values (@exam_id, @question_no, @student_no, @answer_new, 'REQUIRE CHECK', @answer_fill_in_date, null)

	exec tSQLt.ExpectNoException

    exec pr_update_answer @student_no, @exam_id, @question_no, @answer_new
   
   -- Fill in dates gelijk trekken. 
    update ANSWER
	set answer_fill_in_date = @answer_fill_in_date
	where student_no = @student_no and exam_id = @exam_id and question_no = @question_no

	exec tSQLt.AssertEqualsTable 'expected', 'ANSWER'

end
go