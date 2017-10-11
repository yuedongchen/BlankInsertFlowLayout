//
//  BlankInsertFlowLayout.m
//  InstaGrab
//
//  Created by 陈越东 on 16/11/4.
//  Copyright © 2016年 JellyKit Inc. All rights reserved.
//

#import "BlankInsertFlowLayout.h"

@interface BlankInsertFlowLayout ()

@property (nonatomic, strong) NSMutableArray *layoutAttributesArray;

@end

@implementation BlankInsertFlowLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

- (void)prepareLayout
{
    [super prepareLayout];
    self.layoutAttributesArray = [self creatItemsInVisibleRectArray];
}

- (CGSize)collectionViewContentSize
{
    UICollectionViewLayoutAttributes *attributes = [self.layoutAttributesArray lastObject];
    return CGSizeMake([UIScreen mainScreen].bounds.size.width, MAX(attributes.frame.origin.y + attributes.size.height, 700));
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *array = [self.layoutAttributesArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *evaluatedObject, NSDictionary *bindings) {
        return CGRectIntersectsRect(rect, [evaluatedObject frame]);
    }]];
    
    for (UICollectionViewLayoutAttributes *attrs in array) {
        if ([attrs.representedElementKind isEqualToString:UICollectionElementKindSectionHeader] && attrs.indexPath.section == 0) {
            CGRect headerRect = [attrs frame];
            CGFloat offsetY = self.collectionView.contentOffset.y;
            headerRect.size.height = attrs.size.height - MIN(offsetY, 0);
            headerRect.origin.y = MIN(offsetY, 0);
            [attrs setFrame:headerRect];
            break;
//            CGFloat offsetY = self.collectionView.contentOffset.y;
//            attrs.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, MIN(offsetY, 0)), 1, -offsetY / attrs.size.height + 1);
//            break;
        }
    }
    
    return array;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (NSMutableArray *)creatItemsInVisibleRectArray
{
    NSMutableArray *itemsInVisibleRectArray = [NSMutableArray array];
    CGFloat beforeSectionBottom = 0;
    for (NSInteger i = 0; i < [[self collectionView] numberOfSections]; i++) {
        NSInteger itemCount = [[self collectionView] numberOfItemsInSection:i];
        
        UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:i]];
        layoutAttributes.frame = CGRectMake(0, beforeSectionBottom, [self.delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:i].width, [self.delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:i].height);
        [itemsInVisibleRectArray addObject:layoutAttributes];
        
        NSMutableArray *blankAreaArray = [NSMutableArray arrayWithObject:[NSValue valueWithCGRect:CGRectZero]];
        UIEdgeInsets sectionInset = [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:i];
        CGFloat minimumLineSpacing = [self.delegate collectionView:self.collectionView layout:self minimumLineSpacingForSectionAtIndex:i];
        CGFloat minimumInteritemSpacing = [self.delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:i];
        
        CGFloat xOffset = sectionInset.left;
        CGFloat yOffset = sectionInset.top + [self.delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:i].height + beforeSectionBottom;
        CGFloat xNextOffset = sectionInset.left;
        CGFloat yNextOffset = sectionInset.top + [self.delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:i].height + beforeSectionBottom;
        for (NSInteger idx = 0; idx < itemCount; idx++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:i];
            CGSize itemSize = [self.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
            
            BOOL hasInserted = NO;
            for (NSValue *value in blankAreaArray) {
                if (value.CGRectValue.size.width >= itemSize.width) {
                    hasInserted = YES;
                    [blankAreaArray removeObject:value];
                    if (value.CGRectValue.size.width - itemSize.width > minimumInteritemSpacing) {
                        CGRect remainBlankArea = CGRectMake(value.CGRectValue.origin.x + itemSize.width + minimumInteritemSpacing, value.CGRectValue.origin.y, value.CGRectValue.size.width - itemSize.width - minimumInteritemSpacing, value.CGRectValue.size.height);
                        NSValue *remainValue = [NSValue valueWithCGRect:remainBlankArea];
                        [blankAreaArray addObject:remainValue];
                    }
                    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
                    layoutAttributes.frame = CGRectMake(value.CGRectValue.origin.x, value.CGRectValue.origin.y, itemSize.width, itemSize.height);
                    [itemsInVisibleRectArray addObject:layoutAttributes];
                    break;
                }
            }
            if (hasInserted) {
                continue;
            }
            
            xNextOffset += (minimumInteritemSpacing + itemSize.width);
            if ((int)xNextOffset > [self collectionView].bounds.size.width - sectionInset.right + minimumInteritemSpacing) {
                
                if ([self collectionView].bounds.size.width - xNextOffset + (minimumInteritemSpacing + itemSize.width) > minimumInteritemSpacing) {
                    CGRect blankArea = CGRectMake(xNextOffset - (minimumInteritemSpacing + itemSize.width), yOffset, [self collectionView].bounds.size.width - xNextOffset + (minimumInteritemSpacing + itemSize.width), itemSize.height);
                    NSValue *value = [NSValue valueWithCGRect:blankArea];
                    [blankAreaArray addObject:value];
                }
                
                xOffset = sectionInset.left;
                xNextOffset = (sectionInset.left + minimumInteritemSpacing + itemSize.width);
                
                //UICollectionViewLayoutAttributes *beforeLayoutAttributes = []
                yOffset = yNextOffset;
                yNextOffset = yOffset + itemSize.height + minimumLineSpacing;
            } else {
                xOffset = xNextOffset - (minimumInteritemSpacing + itemSize.width);
                yNextOffset = yOffset + itemSize.height + minimumLineSpacing;
            }
            
            UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            layoutAttributes.frame = CGRectMake(xOffset, yOffset, itemSize.width, itemSize.height);
            [itemsInVisibleRectArray addObject:layoutAttributes];
        }
        UICollectionViewLayoutAttributes *LastLayoutAttributes = [itemsInVisibleRectArray lastObject];
        beforeSectionBottom = LastLayoutAttributes.frame.origin.y + LastLayoutAttributes.frame.size.height;
    }
    
    return itemsInVisibleRectArray;
}

@end
