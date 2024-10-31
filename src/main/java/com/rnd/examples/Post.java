package com.rnd.examples;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import org.hibernate.annotations.SoftDelete;

import java.sql.Date;
import java.util.ArrayList;
import java.util.List;

/**
 * Copyright https://vladmihalcea.com/hibernate-softdelete-annotation/
 */
@Entity
@Table(name = "post")
@SoftDelete
public class Post {

    @Id
    private Long id;

    private String title;

    @OneToMany(
            mappedBy = "post",
            cascade = CascadeType.ALL,
            orphanRemoval = true
    )
    private List<PostComment> comments = new ArrayList<>();

    @OneToOne(
            mappedBy = "post",
            cascade = CascadeType.ALL,
            orphanRemoval = true,
            fetch = FetchType.LAZY
    )
    private PostDetails details;

    @ManyToMany
    @JoinTable(
            name = "post_tag",
            joinColumns = @JoinColumn(name = "post_id"),
            inverseJoinColumns = @JoinColumn(name = "tag_id")
    )
    @SoftDelete
    private List<Tag> tags = new ArrayList<>();

    public Post addComment(PostComment comment) {
        comments.add(comment);
        comment.setPost(this);
        return this;
    }

    public Post removeComment(PostComment comment) {
        comments.remove(comment);
        comment.setPost(null);
        return this;
    }

    public Post addDetails(PostDetails details) {
        this.details = details;
        details.setPost(this);
        return this;
    }

    public Post removeDetails() {
        this.details.setPost(null);
        this.details = null;
        return this;
    }

    public Post addTag(Tag tag) {
        tags.add(tag);
        return this;
    }
}

@Entity
@Table(name = "post_details")
@SoftDelete
class PostDetails {

    @Id
    private Long id;

    @Column(name = "created_on")
    private Date createdOn;

    @Column(name = "created_by")
    private String createdBy;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id")
    @MapsId
    private Post post;
}

class RemoveAll {
    public static void main(String[] args) {
        Post post = entityManager.createQuery("""
            select p
            from Post p
            join fetch p.comments
            join fetch p.details
            where p.id = :id
            """, Post.class)
                .setParameter("id", 1L)
                .getSingleResult();

        entityManager.remove(post);

        // Hibernate generates the following SQL UPDATE statements:
        // Query:["update post_tag set deleted=true where post_id=? and deleted=false"], Params:[(1)]
        // Query:["update post_comment set deleted=true where id=? and deleted=false"], Params:[(1)]
        // Query:["update post_comment set deleted=true where id=? and deleted=false"], Params:[(2)]
        // Query:["update post_details set deleted=true where id=? and deleted=false"], Params:[(1)]
        // Query:["update post set deleted=true where id=? and deleted=false"], Params:[(1)]
    }
}

class MyComments {
    public static void main(String[] args) {
//        Soft deleted entity will remain in the cache and if it’s not cleared/flushed it can be accesed by EntityManager.find()
//        EntityManager.refresh() does not fail with @SoftDelete
//        Hard delete – only via native query
    }
}